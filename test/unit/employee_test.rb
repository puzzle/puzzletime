require File.dirname(__FILE__) + '/../test_helper'

class EmployeeTest < Test::Unit::TestCase
  fixtures :employees, :employments
  
  def setup
  end

  def test_half_year_employment
    employee = Employee.find(1)
    period = yearPeriod(employee)    
    assert_equal employee.employmentsDuring(period).size, 1
    assert_equal employee.remainingVacations(period), 10.08
    assert_equal employee.usedVacations(period), 0
    assert_equal employee.totalVacations(period), 10.08
    assert_equal employee.overtime(period), - 127 * 8
  end
  
  def test_various_employment
    employee = Employee.find(2)
    period = yearPeriod(employee)
    employments = employee.employmentsDuring(period)
    assert_equal employments.size, 3
    assert_equal employments[0].start_date, Date.new(2005, 11, 1)
    assert_equal employments[0].end_date, Date.new(2006, 1, 31)
    assert_equal employments[0].period.length, 92
    assert_equal employments[0].vacations, 2.02
    assert_equal employments[1].vacations, 150 / 12.0 * 0.2 - 0.01
    assert_equal employments[2].vacations, 5.86
    assert_in_delta 10.37, employee.remainingVacations(period), 0.01
    assert_equal employee.usedVacations(period), 0
    assert_in_delta 10.37, employee.totalVacations(period), 0.01
    assert_equal employee.overtime(period), - (64*0.4*8 + 162*0.2*8 + 73*8)
  end
  
  def test_next_year_employment
    employee = Employee.find(3)
    period = yearPeriod(employee)  
    assert_equal employee.employmentsDuring(period).size, 0
    assert_equal employee.remainingVacations(period), 0 
    assert_equal employee.usedVacations(period), 0
    assert_equal employee.totalVacations(period), 0
    assert_equal employee.overtime(period), 0
  end
  
  def test_left_this_year_employment
    employee = Employee.find(4)
    period = yearPeriod(employee)  
    assert_equal employee.employmentsDuring(period).size, 1
    assert_equal employee.remainingVacations(period), 30 * 0.8 - 0.08 
    assert_equal employee.usedVacations(period), 0
    assert_equal employee.totalVacations(period), 30 * 0.8 - 0.08
    assert_equal employee.overtime(period), - 387 * 8 * 0.8
  end
  
  def test_long_time_employment
    employee = Employee.find(5)
    period = yearPeriod(employee)  
    assert_equal employee.employmentsDuring(period).size, 1
    assert_equal employee.remainingVacations(period), 17 * 20 * 0.9 - 0.01
    assert_equal employee.usedVacations(period), 0
    assert_equal employee.totalVacations(period), 17 * 20 * 0.9 - 0.01
    assert_equal employee.overtime(period), - 31500
  end
  
private

  def yearPeriod(employee)
    employee.employmentPeriodTo(Date.new(2006,12,31))
  end
  
end
