#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class PeriodTest < ActiveSupport::TestCase
  def setup
    @half_year = Period.new(Date.new(2006, 1, 1), Date.new(2006, 6, 30))
    @one_month = Period.new(Date.new(2006, 3, 1), Date.new(2006, 3, 31))
    @two_month = Period.new(Date.new(2005, 12, 1), Date.new(2006, 1, 31))
    @one_day = Period.new(Date.new(2006, 1, 3), Date.new(2006, 1, 3))
    @holy_day = Period.new(Date.new(2006, 1, 1), Date.new(2006, 1, 1))
  end

  def test_parse
    travel_to Date.new(2000, 1, 5)
    period = Period.parse('3M')
    assert_equal '3M', period.shortcut
    assert_equal Date.new(2000, 1, 3), period.start_date
    assert_equal Date.new(2000, 1, 3) + 3.months, period.end_date
    travel_back
  end

  def test_parse_quarter
    travel_to Date.new(2000, 1, 1)

    period = Period.parse('1q')
    assert_equal '1q', period.shortcut
    assert_equal Date.new(2000, 1, 1), period.start_date
    assert_equal Date.new(2000, 1, 1) + 3.months - 1.day, period.end_date
    period = Period.parse('2q')
    assert_equal '2q', period.shortcut
    assert_equal Date.new(2000, 4, 1), period.start_date
    assert_equal Date.new(2000, 4, 1) + 3.months - 1.day, period.end_date
    period = Period.parse('3q')
    assert_equal '3q', period.shortcut
    assert_equal Date.new(2000, 7, 1), period.start_date
    assert_equal Date.new(2000, 7, 1) + 3.months - 1.day, period.end_date
    period = Period.parse('4q')
    assert_equal '4q', period.shortcut
    assert_equal Date.new(2000, 10, 1), period.start_date
    assert_equal Date.new(2000, 10, 1) + 3.months - 1.day, period.end_date

    assert_raises ArgumentError do
      Period.parse('-1q')
    end

    assert_raises ArgumentError do
      Period.parse('0q')
    end

    assert_raises ArgumentError do
      Period.parse('5q')
    end

    travel_back
  end

  def test_parse_business_year
    Settings.defaults.business_year_start_month = 1

    travel_to Date.new(2000, 1, 15)
    period = Period.parse('b')
    assert_equal 'b', period.shortcut
    assert_equal Date.new(2000, 1, 1), period.start_date
    assert_equal Date.new(2000, 4, 30), period.end_date

    travel_to Date.new(2000, 2, 15)
    period = Period.parse('b')
    assert_equal 'b', period.shortcut
    assert_equal Date.new(2000, 1, 1), period.start_date
    assert_equal Date.new(2000, 5, 31), period.end_date

    travel_to Date.new(2000, 12, 15)
    period = Period.parse('b')
    assert_equal 'b', period.shortcut
    assert_equal Date.new(2000, 1, 1), period.start_date
    assert_equal Date.new(2001, 3, 31), period.end_date

    travel_to Date.new(2001, 1, 15)
    period = Period.parse('b')
    assert_equal 'b', period.shortcut
    assert_equal Date.new(2001, 1, 1), period.start_date
    assert_equal Date.new(2001, 4, 30), period.end_date

    travel_to Date.new(1999, 12, 15)
    period = Period.parse('b')
    assert_equal 'b', period.shortcut
    assert_equal Date.new(1999, 1, 1), period.start_date
    assert_equal Date.new(2000, 3, 31), period.end_date

    Settings.defaults.business_year_start_month = 3

    travel_to Date.new(2000, 1, 15)
    period = Period.parse('b')
    assert_equal 'b', period.shortcut
    assert_equal Date.new(1999, 3, 1), period.start_date
    assert_equal Date.new(2000, 4, 30), period.end_date

    Settings.defaults.business_year_start_month = 7

    travel_to Date.new(2000, 1, 15)
    period = Period.parse('b')
    assert_equal 'b', period.shortcut
    assert_equal Date.new(1999, 7, 1), period.start_date
    assert_equal Date.new(2000, 4, 30), period.end_date

    travel_to Date.new(2000, 6, 15)
    period = Period.parse('b')
    assert_equal 'b', period.shortcut
    assert_equal Date.new(1999, 7, 1), period.start_date
    assert_equal Date.new(2000, 9, 30), period.end_date

    travel_to Date.new(2000, 7, 15)
    period = Period.parse('b')
    assert_equal 'b', period.shortcut
    assert_equal Date.new(2000, 7, 1), period.start_date
    assert_equal Date.new(2000, 10, 31), period.end_date

    travel_back
  end

  def test_intersect
    assert_equal Period.new(nil, nil), Period.new(nil, nil) & Period.new(nil, nil)

    assert_equal Period.new('1.1.1000', nil), Period.new(nil, nil) & Period.new('1.1.1000', nil)
    assert_equal Period.new('1.1.1000', nil), Period.new('1.1.1000', nil) & Period.new(nil, nil)

    assert_equal Period.new(nil, '1.1.1000'), Period.new(nil, nil) & Period.new(nil, '1.1.1000')
    assert_equal Period.new(nil, '1.1.1000'), Period.new(nil, '1.1.1000') & Period.new(nil, nil)

    assert_equal Period.new('1.1.1000', '1.1.2000'), Period.new(nil, nil) & Period.new('1.1.1000', '1.1.2000')
    assert_equal Period.new('1.1.1000', '1.1.2000'), Period.new('1.1.1000', '1.1.2000') & Period.new(nil, nil)

    assert_equal Period.new('1.1.1000', '1.1.2000'), Period.new('1.1.1000', nil) & Period.new(nil, '1.1.2000')
    assert_equal Period.new('1.1.1000', '1.1.2000'), Period.new(nil, '1.1.2000') & Period.new('1.1.1000', nil)

    assert_equal Period.new('1.1.2000', '1.1.3000'), Period.new('1.1.1000', '1.1.3000') & Period.new('1.1.2000', '1.1.4000')
  end

  def test_step
    count = 0
    @half_year.step { |_d| count += 1 }
    assert_equal count, 181
    count = 0
    @one_month.step { |_d| count += 1 }
    assert_equal count, 31
    count = 0
    @two_month.step { |_d| count += 1 }
    assert_equal count, 62
    count = 0
    @one_day.step { |_d| count += 1 }
    assert_equal count, 1
  end

  def test_step_months
    count = 0
    @half_year.step_months { |_d| count += 1 }
    assert_equal count, 6
    count = 0
    @one_month.step_months { |_d| count += 1 }
    assert_equal count, 1
    count = 0
    @two_month.step_months { |_d| count += 1 }
    assert_equal count, 2
    count = 0
    @one_day.step_months { |_d| count += 1 }
    assert_equal count, 1
    count = 0
    two_months_middle = Period.new(Date.new(2005, 12, 15), Date.new(2006, 1, 15))
    two_months_middle.step_months { |_d| count += 1}
    assert_equal count, 2
  end

  def test_length
    assert_equal @half_year.length, 181
    assert_equal @one_month.length, 31
    assert_equal @two_month.length, 62
    assert_equal @one_day.length, 1
  end

  def test_musttime
    assert_equal @half_year.musttime, 129 * 8
    assert_equal @one_month.musttime, 23 * 8
    assert_equal @two_month.musttime, 42 * 8
    assert_equal @one_day.musttime, 8
    assert_equal @holy_day.musttime, 0
  end

  def test_limited
    assert !Period.new(nil, nil).limited?
    assert !Period.new('1.1.1000', nil).limited?
    assert !Period.new(nil, '1.1.2000').limited?
    assert Period.new('1.1.1000', '1.1.2000').limited?
  end

  def test_unlimited
    assert Period.new(nil, nil).unlimited?
    assert Period.new('1.1.1000', nil).unlimited?
    assert Period.new(nil, '1.1.2000').unlimited?
    assert !Period.new('1.1.1000', '1.1.2000').unlimited?
  end
end
