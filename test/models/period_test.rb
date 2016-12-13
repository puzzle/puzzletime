# encoding: utf-8

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
