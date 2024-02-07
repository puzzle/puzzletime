# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class PeriodTest < ActiveSupport::TestCase
  def setup
    setup_regular_holidays([2005, 2006])
    @half_year = Period.new(Date.new(2006, 1, 1), Date.new(2006, 6, 30))
    @one_month = Period.new(Date.new(2006, 3, 1), Date.new(2006, 3, 31))
    @two_month = Period.new(Date.new(2005, 12, 1), Date.new(2006, 1, 31))
    @one_day = Period.new(Date.new(2006, 1, 3), Date.new(2006, 1, 3))
    @holy_day = Period.new(Date.new(2006, 1, 1), Date.new(2006, 1, 1))
  end

  def test_vacation_days_per_year_factors
    assert_in_delta(1.0, Period.new(Date.new(2000, 1, 1), Date.new(2000, 12, 31)).vacation_factor_sum)
    assert_in_delta(1.0, Period.new(Date.new(2001, 1, 1), Date.new(2001, 12, 31)).vacation_factor_sum)
    assert_in_delta(2.0, Period.new(Date.new(2000, 1, 1), Date.new(2001, 12, 31)).vacation_factor_sum)
    assert_in_delta(4.0, Period.new(Date.new(2001, 1, 1), Date.new(2004, 12, 31)).vacation_factor_sum)
    assert_in_delta(5.0, Period.new(Date.new(2000, 1, 1), Date.new(2004, 12, 31)).vacation_factor_sum)

    assert_in_delta 0.497, Period.new(Date.new(2000, 1, 1), Date.new(2000, 6, 30)).vacation_factor_sum
    assert_in_delta 0.495, Period.new(Date.new(2001, 1, 1), Date.new(2001, 6, 30)).vacation_factor_sum

    assert_in_delta 1.495, Period.new(Date.new(2000, 1, 1), Date.new(2001, 6, 30)).vacation_factor_sum
    assert_in_delta 1.495, Period.new(Date.new(2001, 1, 1), Date.new(2002, 6, 30)).vacation_factor_sum
    assert_in_delta 0.005, Period.new(Date.new(2000, 12, 1), Date.new(2000, 12, 2)).vacation_factor_sum

    assert_in_delta(6.0, Period.new(Date.new(2000, 1, 1), Date.new(2005, 12, 31)).vacation_factor_sum)
    assert_in_delta(4.0, Period.new(Date.new(2000, 1, 1), Date.new(2003, 12, 31)).vacation_factor_sum)

    assert_equal 0, Period.new(Date.new(2004, 1, 1), Date.new(2003, 12, 31)).vacation_factor_sum
    assert_equal 0, Period.new(Date.new(2004, 12, 31), Date.new(2004, 12, 1)).vacation_factor_sum
  end

  def test_parse
    travel_to Date.new(2000, 1, 5)
    period = Period.parse('3M')

    assert_equal '3M', period.shortcut
    assert_equal Date.new(2000, 1, 3), period.start_date
    assert_equal Date.new(2000, 1, 3) + 3.months, period.end_date
    travel_back
  end

  def test_parse_current_quarter
    travel_to Date.new(2000, 1, 1)

    period = Period.parse('1Q')

    assert_equal '1Q', period.shortcut
    assert_equal Date.new(2000, 1, 1), period.start_date
    assert_equal Date.new(2000, 1, 1) + 3.months - 1.day, period.end_date
    period = Period.parse('2Q')

    assert_equal '2Q', period.shortcut
    assert_equal Date.new(2000, 4, 1), period.start_date
    assert_equal Date.new(2000, 4, 1) + 3.months - 1.day, period.end_date
    period = Period.parse('3Q')

    assert_equal '3Q', period.shortcut
    assert_equal Date.new(2000, 7, 1), period.start_date
    assert_equal Date.new(2000, 7, 1) + 3.months - 1.day, period.end_date
    period = Period.parse('4Q')

    assert_equal '4Q', period.shortcut
    assert_equal Date.new(2000, 10, 1), period.start_date
    assert_equal Date.new(2000, 10, 1) + 3.months - 1.day, period.end_date

    assert_raises ArgumentError do
      Period.parse('-1Q')
    end

    assert_raises ArgumentError do
      Period.parse('0Q')
    end

    assert_raises ArgumentError do
      Period.parse('5Q')
    end

    travel_back
  end

  def test_parse_quarter
    travel_to Date.new(2000, 1, 1)

    period = Period.parse('0q')

    assert_equal '0q', period.shortcut
    assert_equal Date.new(2000, 1, 1), period.start_date
    assert_equal Date.new(2000, 1, 1) + 3.months - 1.day, period.end_date

    period = Period.parse('-1q')

    assert_equal '-1q', period.shortcut
    assert_equal Date.new(1999, 10, 1), period.start_date
    assert_equal Date.new(1999, 10, 1) + 3.months - 1.day, period.end_date

    period = Period.parse('-2q')

    assert_equal '-2q', period.shortcut
    assert_equal Date.new(1999, 7, 1), period.start_date
    assert_equal Date.new(1999, 7, 1) + 3.months - 1.day, period.end_date

    period = Period.parse('-3q')

    assert_equal '-3q', period.shortcut
    assert_equal Date.new(1999, 4, 1), period.start_date
    assert_equal Date.new(1999, 4, 1) + 3.months - 1.day, period.end_date

    period = Period.parse('-4q')

    assert_equal '-4q', period.shortcut
    assert_equal Date.new(1999, 1, 1), period.start_date
    assert_equal Date.new(1999, 1, 1) + 3.months - 1.day, period.end_date

    period = Period.parse('-5q')

    assert_equal '-5q', period.shortcut
    assert_equal Date.new(1998, 10, 1), period.start_date
    assert_equal Date.new(1998, 10, 1) + 3.months - 1.day, period.end_date

    period = Period.parse('1q')

    assert_equal '1q', period.shortcut
    assert_equal Date.new(2000, 4, 1), period.start_date
    assert_equal Date.new(2000, 4, 1) + 3.months - 1.day, period.end_date

    period = Period.parse('2q')

    assert_equal '2q', period.shortcut
    assert_equal Date.new(2000, 7, 1), period.start_date
    assert_equal Date.new(2000, 7, 1) + 3.months - 1.day, period.end_date

    period = Period.parse('3q')

    assert_equal '3q', period.shortcut
    assert_equal Date.new(2000, 10, 1), period.start_date
    assert_equal Date.new(2000, 10, 1) + 3.months - 1.day, period.end_date

    period = Period.parse('4q')

    assert_equal '4q', period.shortcut
    assert_equal Date.new(2001, 1, 1), period.start_date
    assert_equal Date.new(2001, 1, 1) + 3.months - 1.day, period.end_date

    period = Period.parse('5q')

    assert_equal '5q', period.shortcut
    assert_equal Date.new(2001, 4, 1), period.start_date
    assert_equal Date.new(2001, 4, 1) + 3.months - 1.day, period.end_date

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

    assert_equal Period.new('1.1.2000', '1.1.3000'),
                 Period.new('1.1.1000', '1.1.3000') & Period.new('1.1.2000', '1.1.4000')
  end

  def test_step
    count = 0
    @half_year.step { |_d| count += 1 }

    assert_equal 181, count
    count = 0
    @one_month.step { |_d| count += 1 }

    assert_equal 31, count
    count = 0
    @two_month.step { |_d| count += 1 }

    assert_equal 62, count
    count = 0
    @one_day.step { |_d| count += 1 }

    assert_equal 1, count
  end

  def test_step_months
    count = 0
    @half_year.step_months { |_d| count += 1 }

    assert_equal 6, count
    count = 0
    @one_month.step_months { |_d| count += 1 }

    assert_equal 1, count
    count = 0
    @two_month.step_months { |_d| count += 1 }

    assert_equal 2, count
    count = 0
    @one_day.step_months { |_d| count += 1 }

    assert_equal 1, count
    count = 0
    two_months_middle = Period.new(Date.new(2005, 12, 15), Date.new(2006, 1, 15))
    two_months_middle.step_months { |_d| count += 1 }

    assert_equal 2, count
  end

  def test_length
    assert_equal 181, @half_year.length
    assert_equal 31, @one_month.length
    assert_equal 62, @two_month.length
    assert_equal 1, @one_day.length
  end

  def test_musttime
    assert_equal 129 * 8, @half_year.musttime
    assert_equal 23 * 8, @one_month.musttime
    assert_equal 42 * 8, @two_month.musttime
    assert_equal 8, @one_day.musttime
    assert_equal 0, @holy_day.musttime
  end

  def test_limited
    assert_not Period.new(nil, nil).limited?
    assert_not Period.new('1.1.1000', nil).limited?
    assert_not Period.new(nil, '1.1.2000').limited?
    assert_predicate Period.new('1.1.1000', '1.1.2000'), :limited?
  end

  def test_unlimited
    assert_predicate Period.new(nil, nil), :unlimited?
    assert_predicate Period.new('1.1.1000', nil), :unlimited?
    assert_predicate Period.new(nil, '1.1.2000'), :unlimited?
    assert_not Period.new('1.1.1000', '1.1.2000').unlimited?
  end
end
