require File.dirname(__FILE__) + '/../test_helper'

class WeekTest < Test::Unit::TestCase
  
  def test_from_string
    week = Week.from_string("2009 10")
    assert_equal 10, week.week
    assert_equal 2009, week.year

    week = Week.from_string("1999 01")
    assert_equal 1, week.week
    assert_equal 1999, week.year

    week = Week.from_string("1999 1")
    assert_equal 1, week.week
    assert_equal 1999, week.year
  end
  
  def test_from_integer
    week = Week.from_integer(200811)
    assert_equal 11, week.week
    assert_equal 2008, week.year

    week = Week.from_integer(197004)
    assert_equal 4, week.week
    assert_equal 1970, week.year
    
  end
  
  def test_to_integer
    week = Week.from_string("2007 01")
    assert_equal 200701, week.to_integer

    week = Week.from_integer(200811)
    assert_equal 200811, week.to_integer
  end

  def test_from_date
    week = Week::from_date(Date.civil(2010,3,16))
    assert_equal 201011, week.to_integer

    week = Week::from_date(Date.civil(2010,3,1))
    assert_equal 201009, week.to_integer
  end
  
  def test_valid_week
    assert Week::valid?(201001)
    assert !Week::valid?(201053)
  end
  
end
