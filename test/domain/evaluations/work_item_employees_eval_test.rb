#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require_relative 'eval_test_helper'

class Evaluations::EmployeeWorkItemsEvalTest < ActiveSupport::TestCase
  include EvalTestHelper

  def test_project_employees_allgemein
    @evaluation = Evaluations::WorkItemEmployeesEval.new(work_items(:allgemein).id)

    assert_not @evaluation.absences?
    assert_not @evaluation.for?(employees(:pascal))
    assert @evaluation.total_details

    divisions = @evaluation.divisions.list.to_a

    assert_equal 3, divisions.size
    assert_equal employees(:mark), divisions[0]
    assert_equal employees(:lucien), divisions[1]
    assert_equal employees(:pascal), divisions[2]

    assert_sum_times 0, 5, 5, 5, employees(:mark)
    assert_sum_times 0, 9, 9, 9, employees(:lucien)
    assert_sum_times 0, 0, 0, 1, employees(:pascal)

    assert_empty(@evaluation.sum_times_grouped(@period_day))
    assert_equal({ employees(:mark).id => { hours: 5.0, billable_hours: 5.0 },
                   employees(:lucien).id => { hours: 9.0, billable_hours: 9.0 } },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ employees(:mark).id => { hours: 5.0, billable_hours: 5.0 },
                   employees(:lucien).id => { hours: 9.0, billable_hours: 9.0 } },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times({ hours: 0.0, billable_hours: 0.0 },
                           { hours: 14.0, billable_hours: 14.0 },
                           { hours: 14.0, billable_hours: 14.0 },
                           { hours: 15.0, billable_hours: 15.0 })
  end

  def test_project_employees_allgemein_detail
    @evaluation = Evaluations::WorkItemEmployeesEval.new(work_items(:allgemein).id)

    @evaluation.set_division_id(employees(:mark).id)

    assert_sum_times 0, 5, 5, 5
    assert_count_times 0, 1, 1, 1

    @evaluation.set_division_id(employees(:pascal).id)

    assert_sum_times 0, 0, 0, 1
    assert_count_times 0, 0, 0, 1
  end

  def test_project_employees_puzzletime
    @evaluation = Evaluations::WorkItemEmployeesEval.new(work_items(:puzzletime).id)

    assert_not @evaluation.absences?
    assert_not @evaluation.for?(employees(:pascal))
    assert @evaluation.total_details

    divisions = @evaluation.divisions.list.to_a

    assert_equal 3, divisions.size
    assert_equal employees(:mark), divisions[0]
    assert_equal employees(:lucien), divisions[1]
    assert_equal employees(:pascal), divisions[2]

    assert_sum_times 0, 6, 6, 6, employees(:mark)
    assert_sum_times 0, 0, 10, 10, employees(:lucien)
    assert_sum_times 0, 0, 2, 2, employees(:pascal)

    assert_empty(@evaluation.sum_times_grouped(@period_day))
    assert_equal({ employees(:mark).id => { hours: 6.0, billable_hours: 6.0 } },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ employees(:mark).id => { hours: 6.0, billable_hours: 6.0 },
                   employees(:pascal).id => { hours: 2.0, billable_hours: 2.0 },
                   employees(:lucien).id => { hours: 10.0, billable_hours: 0.0 } },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times({ hours: 0.0, billable_hours: 0.0 },
                           { hours: 6.0, billable_hours: 6.0 },
                           { hours: 18.0, billable_hours: 8.0 },
                           { hours: 18.0, billable_hours: 8.0 })
  end

  def test_project_employees_puzzletime_detail
    @evaluation = Evaluations::WorkItemEmployeesEval.new(work_items(:puzzletime).id)

    @evaluation.set_division_id(employees(:pascal).id)

    assert_sum_times 0, 0, 2, 2
    assert_count_times 0, 0, 1, 1
  end

  def test_project_employees_webauftritt
    @evaluation = Evaluations::WorkItemEmployeesEval.new(work_items(:webauftritt).id)

    assert_not @evaluation.absences?
    assert_not @evaluation.for?(employees(:lucien))
    assert @evaluation.total_details

    Fabricate(:planning, work_item: work_items(:webauftritt), employee: employees(:long_time_john))

    divisions = @evaluation.divisions.list.to_a

    assert_equal 4, divisions.size
    assert_equal employees(:long_time_john), divisions[0]
    assert_equal employees(:mark), divisions[1]
    assert_equal employees(:lucien), divisions[2]
    assert_equal employees(:pascal), divisions[3]

    assert_sum_times 0, 7, 7, 7, employees(:mark)
    assert_sum_times 0, 0, 11, 11, employees(:lucien)
    assert_sum_times 3, 3, 3, 3, employees(:pascal)

    assert_equal({ employees(:pascal).id => { hours: 3.0, billable_hours: 0.0 } },
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ employees(:pascal).id => { hours: 3.0, billable_hours: 0.0 },
                   employees(:mark).id => { hours: 7.0, billable_hours: 7.0 } },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ employees(:lucien).id => { hours: 11.0, billable_hours: 11.0 },
                   employees(:pascal).id => { hours: 3.0, billable_hours: 0.0 },
                   employees(:mark).id => { hours: 7.0, billable_hours: 7.0 } },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times({ hours: 3.0, billable_hours: 0.0 },
                           { hours: 10.0, billable_hours: 7.0 },
                           { hours: 21.0, billable_hours: 18.0 },
                           { hours: 21.0, billable_hours: 18.0 })
  end

  def test_project_employees_webauftritt_detail
    @evaluation = Evaluations::WorkItemEmployeesEval.new(work_items(:webauftritt).id)

    @evaluation.set_division_id(employees(:lucien).id)

    assert_sum_times 0, 0, 11, 11
    assert_count_times 0, 0, 1, 1
  end
end
