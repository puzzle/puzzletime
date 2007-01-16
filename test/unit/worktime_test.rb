require File.dirname(__FILE__) + '/../test_helper'

class WorktimeTest < Test::Unit::TestCase
  fixtures :worktimes
  
  def setup
    @worktime = Worktime.new
  end
  
  def test_time_facade
    time_facade('from_start_time')
    time_facade('to_end_time')
  end
  
  def time_facade(field)
    now = Time.now    
    set_field(field, now)
    assert_equal_time_field now, field    
    #set_field(field, now.to_s)
    #assert_equal_time_field now, field    
    set_field(field, "3")
    assert_equal_time_field Time.parse("3:00"), field    
    set_field(field, "4:14")
    assert_equal_time_field Time.parse("4:14"), field    
    set_field(field, "23:14")
    assert_equal_time_field Time.parse("23:14"), field    
    set_field(field, "4.25")
    assert_equal_time_field Time.parse("4:15"), field    
    set_field(field, "4.0")
    assert_equal_time_field Time.parse("4:00"), field
  end
  
  def test_time_facade_invalid
    time_facade_invalid('from_start_time')
    time_facade_invalid('to_end_time')
  end
  
  def time_facade_invalid(field)
    set_field(field, "")
    assert_nil get_field(field)
    set_field(field, "adfasf")
    assert_nil get_field(field)
    set_field(field, "ss:22")
    assert_nil get_field(field)
    set_field(field, "1:ss")
    assert_nil get_field(field)
    set_field(field, "1:88")
    assert_nil get_field(field)
    set_field(field, "28")
    assert_nil get_field(field)
    set_field(field, "28:22")
    assert_nil get_field(field)
    set_field(field, "-8")
    assert_nil get_field(field)
  end
  
  def get_field(field)
    @worktime.send(field)
  end
  
  def set_field(field, value)
    @worktime.send(field + '=', value)
  end  
    
  def assert_equal_time_field(time, field)
    assert_equal_time time, @worktime.send(field)
  end
  
  def assert_equal_time(time1, time2)
    assert_equal(time1.hour, time2.hour) && 
    assert_equal(time1.min, time2.min)
  end
  
end
