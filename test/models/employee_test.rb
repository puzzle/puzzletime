#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.
# {{{
# == Schema Information
#
# Table name: employees
#
#  id                        :integer          not null, primary key
#  additional_information    :text
#  birthday                  :date
#  city                      :string
#  committed_worktimes_at    :date
#  crm_key                   :string
#  email                     :string(255)      not null
#  emergency_contact_name    :string
#  emergency_contact_phone   :string
#  encrypted_password        :string           default("")
#  eval_periods              :string(3)        is an Array
#  firstname                 :string(255)      not null
#  graduation                :string
#  identity_card_type        :string
#  identity_card_valid_until :date
#  initial_vacation_days     :float
#  lastname                  :string(255)      not null
#  ldapname                  :string(255)
#  management                :boolean          default(FALSE)
#  marital_status            :integer
#  nationalities             :string           is an Array
#  phone_office              :string
#  phone_private             :string
#  postal_code               :string
#  probation_period_end_date :date
#  remember_created_at       :datetime
#  reviewed_worktimes_at     :date
#  shortname                 :string(3)        not null
#  social_insurance          :string
#  street                    :string
#  worktimes_commit_reminder :boolean          default(TRUE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  department_id             :integer
#  workplace_id              :bigint
#
# Indexes
#
#  chk_unique_name                   (shortname) UNIQUE
#  index_employees_on_department_id  (department_id)
#  index_employees_on_workplace_id   (workplace_id)
#
# }}}

require 'test_helper'

class EmployeeTest < ActiveSupport::TestCase
  def setup
    years = 1990..2006
    setup_regular_holidays(years.to_a)
  end

  def test_half_year_employment
    employee = Employee.find(1)
    period = year_period(employee)

    assert_equal 1, employee.statistics.employments_during(period).size
    assert_in_delta 12.60, employee.statistics.remaining_vacations(period.end_date), 0.005
    assert_equal 0, employee.statistics.used_vacations(period)
    assert_in_delta 12.60, employee.statistics.total_vacations(period), 0.005
    assert_equal -127 * 8, employee.statistics.overtime(period)
  end

  def test_various_employment
    employee = Employee.find(2)
    period = year_period(employee)
    employments = employee.statistics.employments_during(period)

    assert_equal 3, employments.size
    assert_equal employments[0].start_date, Date.new(2005, 11, 1)
    assert_equal employments[0].end_date, Date.new(2006, 1, 31)
    assert_equal 92, employments[0].period.length
    assert_in_delta 2.52, employments[0].vacations, 0.005
    assert_in_delta 3.73, employments[1].vacations, 0.005
    assert_in_delta 7.33, employments[2].vacations, 0.005
    assert_in_delta 13.58, employee.statistics.remaining_vacations(period.end_date), 0.01
    assert_equal 0, employee.statistics.used_vacations(period)
    assert_in_delta 13.58, employee.statistics.total_vacations(period), 0.01
    assert_in_delta 11.90, employee.statistics.total_vacations(Period.year_for(Date.new(2006))), 0.01
    assert_equal employee.statistics.overtime(period), - ((64 * 0.4 * 8) + (162 * 0.2 * 8) + (73 * 8))
  end

  def test_next_year_employment
    employee = Employee.find(3)
    period = year_period(employee)

    assert_equal 0, employee.statistics.employments_during(period).size
    assert_equal 0, employee.statistics.remaining_vacations(Date.new(2006, 12, 31))
    assert_equal 0, employee.statistics.used_vacations(period)
    assert_equal 0, employee.statistics.total_vacations(period)
    assert_equal 0, employee.statistics.overtime(period)
  end

  def test_left_this_year_employment
    employee = Employee.find(4)
    period = year_period(employee)

    assert_equal 1, employee.statistics.employments_during(period).size
    assert_in_delta 29.92, employee.statistics.remaining_vacations(period.end_date), 0.005
    assert_equal 0, employee.statistics.used_vacations(period)
    assert_in_delta 29.92, employee.statistics.total_vacations(period), 0.005
    assert_in_delta((- 387 * 8 * 0.8), employee.statistics.overtime(period), 0.005)
  end

  def test_long_time_employment
    employee = Employee.find(5)
    period = year_period(employee)

    assert_equal 1, employee.statistics.employments_during(period).size
    assert_in_delta 382.5, employee.statistics.remaining_vacations(period.end_date), 0.005
    assert_equal 0, employee.statistics.used_vacations(period)
    assert_in_delta 382.5, employee.statistics.total_vacations(period), 0.005
    assert_equal -31_500, employee.statistics.overtime(period)
  end

  def test_alltime_leaf_work_items
    e = employees(:pascal)

    assert_equal work_items(:allgemein, :puzzletime, :webauftritt), e.alltime_leaf_work_items
  end

  def test_alltime_main_work_items
    e = employees(:pascal)

    assert_equal work_items(:puzzle, :swisstopo), e.alltime_main_work_items
  end

  test 'includes only those employees with billable worktimes in given period' do
    order = orders(:webauftritt)
    from = '01.12.2006'
    to = '11.12.2006'

    empls = Employee.with_worktimes_in_period(order, from, to)

    assert 1, empls.size
    assert_includes empls, employees(:mark)
  end

  test 'includes all employees with billable worktimes for given order if no period specified' do
    order = orders(:webauftritt)
    from = nil
    to = nil

    empls = Employee.with_worktimes_in_period(order, from, to)

    assert_equal 2, empls.size
    assert_includes empls, employees(:mark)
    assert_includes empls, employees(:lucien)
  end

  test '#current scope' do
    refute_equal Employee.count, Employee.current.count
    assert_arrays_match employees(:long_time_john, :various_pedro, :next_year_pablo), Employee.current
  end

  test '#pending_worktimes_commit scope' do
    Employee.update_all(committed_worktimes_at: nil)

    assert_predicate Employee.pending_worktimes_commit, :present?

    Employee.update_all(committed_worktimes_at: Date.today.beginning_of_month - 1.day)

    assert_predicate Employee.pending_worktimes_commit, :blank?

    Employee.update_all(committed_worktimes_at: Date.today.beginning_of_month - 2.days)

    assert_predicate Employee.pending_worktimes_commit, :present?
  end

  private

  def year_period(employee)
    employee.statistics.send :employment_period_to, Date.new(2006, 12, 31)
  end
end
