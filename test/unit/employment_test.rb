require File.dirname(__FILE__) + '/../test_helper'

class EmploymentTest < Test::Unit::TestCase
  fixtures :employments, :masterdatas

  def setup
    @half_year = Employment.find(1)
    @various = Employment.find(2)
    @open_end = Employment.find(4)
  end

  # Replace this with your real tests.
  def test_musttime
    assert_equal @half_year.period.length, 184
    assert_equal @half_year.period.musttime, 127 * 8
    assert_equal @half_year.percentFactor, 1
    assert_equal @half_year.holidays, 10.08
    assert_equal @half_year.musttime, 127* 8
  
    assert_equal @various.period.length, 92
    assert_equal @various.period.musttime, 64 * 8
    assert_equal @various.percentFactor, 0.4
    assert_equal @various.holidays, 2.02
    assert_equal @various.musttime, 64 * 8 * 0.4
    
    @open_end.end_date = Date.new(2006, 12, 31)
    assert_equal @open_end.period.length, 107
    assert_equal @open_end.period.musttime, 73 * 8
    assert_equal @open_end.percentFactor, 1
    assert_equal @open_end.holidays, 5.86
    assert_equal @open_end.musttime, 73 * 8  
  end
end
