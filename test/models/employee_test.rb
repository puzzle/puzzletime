# encoding: utf-8
# == Schema Information
#
# Table name: employees
#
#  id                    :integer          not null, primary key
#  firstname             :string(255)      not null
#  lastname              :string(255)      not null
#  shortname             :string(3)        not null
#  passwd                :string(255)
#  email                 :string(255)      not null
#  management            :boolean          default(FALSE)
#  initial_vacation_days :float
#  ldapname              :string(255)
#  eval_periods          :string           is an Array
#  department_id         :integer
#


require 'test_helper'

class EmployeeTest < ActiveSupport::TestCase


  def test_half_year_employment
    employee = Employee.find(1)
    period = year_period(employee)
    assert_equal employee.statistics.employments_during(period).size, 1
    # assert_in_delta 10.08, employee.statistics.remaining_vacations(period.end_date), 0.005
    assert_equal employee.statistics.used_vacations(period), 0
    # assert_in_delta 10.08, employee.statistics.total_vacations(period), 0.005
    assert_equal employee.statistics.overtime(period), - 127 * 8
  end

  def test_various_employment
    employee = Employee.find(2)
    period = year_period(employee)
    employments = employee.statistics.employments_during(period)
    assert_equal 3, employments.size
    assert_equal employments[0].start_date, Date.new(2005, 11, 1)
    assert_equal employments[0].end_date, Date.new(2006, 1, 31)
    assert_equal employments[0].period.length, 92
    # assert_in_delta 2.02, employments[0].vacations, 0.005
    # assert_in_delta 150 / 12.0 * 0.2 - 0.01, employments[1].vacations, 0.005
    # assert_in_delta 5.86, employments[2].vacations, 0.005
    # assert_in_delta 10.37, employee.statistics.remaining_vacations(period.end_date), 0.01
    assert_equal employee.statistics.used_vacations(period), 0
    # assert_in_delta 10.37, employee.statistics.total_vacations(period), 0.01
    assert_equal employee.statistics.overtime(period), - (64 * 0.4 * 8 + 162 * 0.2 * 8 + 73 * 8)
  end

  def test_next_year_employment
    employee = Employee.find(3)
    period = year_period(employee)
    assert_equal employee.statistics.employments_during(period).size, 0
    assert_equal employee.statistics.remaining_vacations(Date.new(2006, 12, 31)), 0
    assert_equal employee.statistics.used_vacations(period), 0
    assert_equal employee.statistics.total_vacations(period), 0
    assert_equal employee.statistics.overtime(period), 0
  end

  def test_left_this_year_employment
    employee = Employee.find(4)
    period = year_period(employee)
    assert_equal employee.statistics.employments_during(period).size, 1
    # assert_in_delta 30 * 0.8 - 0.08, employee.statistics.remaining_vacations(period.end_date), 0.005
    assert_equal employee.statistics.used_vacations(period), 0
    # assert_in_delta 30 * 0.8 - 0.08, employee.statistics.total_vacations(period), 0.005
    # assert_in_delta( (- 387 * 8 * 0.8), employee.statistics.overtime(period), 0.005)
  end

  def test_long_time_employment
    employee = Employee.find(5)
    period = year_period(employee)
    assert_equal employee.statistics.employments_during(period).size, 1
    # assert_in_delta 17 * 20 * 0.9 - 0.01, employee.statistics.remaining_vacations(period.end_date), 0.005
    assert_equal employee.statistics.used_vacations(period), 0
    # assert_in_delta 17 * 20 * 0.9 - 0.01, employee.statistics.total_vacations(period), 0.005
    assert_equal employee.statistics.overtime(period), - 31_500
  end

  def test_alltime_leaf_work_items
    e = employees(:pascal)
    assert_equal work_items(:allgemein, :puzzletime, :webauftritt), e.alltime_leaf_work_items
  end

  def test_alltime_main_work_items
    e = employees(:pascal)
    assert_equal work_items(:puzzle, :swisstopo), e.alltime_main_work_items
  end

  private

  def year_period(employee)
    employee.statistics.send :employment_period_to, Date.new(2006, 12, 31)
  end

end
