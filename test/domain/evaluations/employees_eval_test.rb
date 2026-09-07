# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require_relative 'eval_test_helper'

module Evaluations
  class EmployeesEvalTest < ActiveSupport::TestCase
    include EvalTestHelper

    def setup
      super
      employees(:pascal).update!(member_coach_id: employees(:mark).id)
      @evaluation = Evaluations::EmployeesEval.new
    end

    def test_employees
      assert_not @evaluation.absences?
      assert_not @evaluation.for?(employees(:pascal))
      assert_not @evaluation.total_details

      divisions = @evaluation.divisions

      assert_equal 3, divisions.size

      assert_sum_times 0, 18, 18, 18, employees(:mark)
      assert_sum_times 0, 9, 30, 30, employees(:lucien)
      assert_sum_times 3, 3, 5, 6, employees(:pascal)

      assert_equal({ employees(:pascal).id => 3.0 },
                   @evaluation.sum_times_grouped(@period_day))
      assert_equal({ employees(:mark).id => 18.0, employees(:lucien).id => 9.0, employees(:pascal).id => 3.0 },
                   @evaluation.sum_times_grouped(@period_week))
      assert_equal({ employees(:mark).id => 18.0, employees(:lucien).id => 30.0, employees(:pascal).id => 5.0 },
                   @evaluation.sum_times_grouped(@period_month))

      assert_sum_total_times 3.0, 30.0, 53.0, 54.0
    end

    def test_employees_by_department
      @evaluation = Evaluations::EmployeesEval.new(department_id: departments(:devtwo).id)

      assert_sum_total_times 3.0, 12.0, 35.0, 36.0
    end

    def test_employees_by_member_coach
      @evaluation = Evaluations::EmployeesEval.new(member_coach_id: employees(:mark).id)

      assert_sum_total_times 3.0, 3.0, 5.0, 6.0
    end

    def test_employee_detail_mark
      @evaluation.set_division_id employees(:mark).id

      assert_sum_times 0, 18, 18, 18
      assert_count_times 0, 3, 3, 3
    end

    def test_employee_detail_lucien
      @evaluation.set_division_id employees(:lucien).id

      assert_sum_times 0, 9, 30, 30
      assert_count_times 0, 1, 3, 3
    end

    def test_employee_detail_pascal
      @evaluation.set_division_id employees(:pascal).id

      assert_sum_times 3, 3, 5, 6
      assert_count_times 1, 1, 2, 3
    end

    def test_employees_sorted_by_worktime_commits
      stub_employee_relation
      employees(:pascal).update!(committed_worktimes_at: Date.new(2020, 6, 1))
      employees(:mark).update!(committed_worktimes_at: Date.new(2021, 6, 1))
      employees(:lucien).update!(committed_worktimes_at: Date.new(2022, 6, 1))

      ascending = Evaluations::EmployeesEval.new({}, { 'sort' => 'worktime_commits', 'sort_dir' => 'asc' })

      assert_equal [employees(:pascal), employees(:mark), employees(:lucien)], ascending.divisions(@period_month)

      descending = Evaluations::EmployeesEval.new({}, { 'sort' => 'worktime_commits', 'sort_dir' => 'desc' })

      assert_equal [employees(:lucien), employees(:mark), employees(:pascal)], descending.divisions(@period_month)
    end

    def test_employees_sorted_by_worktime_reviews
      stub_employee_relation
      employees(:pascal).update!(reviewed_worktimes_at: Date.new(2020, 6, 1))
      employees(:mark).update!(reviewed_worktimes_at: Date.new(2021, 6, 1))
      employees(:lucien).update!(reviewed_worktimes_at: Date.new(2022, 6, 1))

      ascending = Evaluations::EmployeesEval.new({}, { 'sort' => 'worktime_reviews', 'sort_dir' => 'asc' })

      assert_equal [employees(:pascal), employees(:mark), employees(:lucien)], ascending.divisions(@period_month)
    end

    def test_employees_sorted_by_overtime
      stub_employee_objects
      employees(:pascal).stubs(:statistics).returns(stub(overtime: 5.0))
      employees(:mark).stubs(:statistics).returns(stub(overtime: -2.0))
      employees(:lucien).stubs(:statistics).returns(stub(overtime: 10.0))

      ascending = Evaluations::EmployeesEval.new({}, { 'sort' => 'overtime', 'sort_dir' => 'asc' })

      assert_equal [employees(:mark), employees(:pascal), employees(:lucien)], ascending.divisions(@period_month)

      descending = Evaluations::EmployeesEval.new({}, { 'sort' => 'overtime', 'sort_dir' => 'desc' })

      assert_equal [employees(:lucien), employees(:pascal), employees(:mark)], descending.divisions(@period_month)
    end

    def test_employees_sorted_by_vacations
      stub_employee_objects
      employees(:pascal).stubs(:statistics).returns(stub(remaining_vacations: 3.0))
      employees(:mark).stubs(:statistics).returns(stub(remaining_vacations: 12.0))
      employees(:lucien).stubs(:statistics).returns(stub(remaining_vacations: 7.0))

      ascending = Evaluations::EmployeesEval.new({}, { 'sort' => 'vacations', 'sort_dir' => 'asc' })

      assert_equal [employees(:pascal), employees(:lucien), employees(:mark)], ascending.divisions(@period_month)
    end

    def test_employees_sorted_by_period_hours
      stub_employee_relation
      times = [{ employees(:pascal).id => 3.0, employees(:lucien).id => 9.0, employees(:mark).id => 18.0 }]

      ascending = Evaluations::EmployeesEval.new({}, { 'sort' => 'period_hours', 'sort_dir' => 'asc' })

      assert_equal [employees(:pascal), employees(:lucien), employees(:mark)],
                   ascending.divisions(@period_month, times)

      descending = Evaluations::EmployeesEval.new({}, { 'sort' => 'period_hours', 'sort_dir' => 'desc' })

      assert_equal [employees(:mark), employees(:lucien), employees(:pascal)],
                   descending.divisions(@period_month, times)
    end

    def test_employees_sorted_by_period_hours_defaults_missing_employees_to_zero
      stub_employee_relation
      # lucien has no entry, i.e. no worktimes at all in the period
      times = [{ employees(:pascal).id => 3.0, employees(:mark).id => 1.0 }]

      ascending = Evaluations::EmployeesEval.new({}, { 'sort' => 'period_hours', 'sort_dir' => 'asc' })

      assert_equal [employees(:lucien), employees(:mark), employees(:pascal)],
                   ascending.divisions(@period_month, times)
    end

    private

    # Restricts Employee.list to a real relation of exactly the 3 employees these
    # tests care about, so a real SQL ORDER BY (reorder) can still run on it.
    def stub_employee_relation
      ids = [employees(:pascal).id, employees(:mark).id, employees(:lucien).id]
      Employee.stubs(:list).returns(Employee.where(id: ids))
    end

    # Restricts Employee.list to the exact fixture instances, so a per-instance
    # stub (e.g. on #statistics) set on them is still in effect when read back.
    def stub_employee_objects
      Employee.stubs(:list).returns([employees(:pascal), employees(:mark), employees(:lucien)])
    end
  end
end
