require 'test_helper'
require_relative 'eval_test_helper'

class EmployeeWorkItemsEvalTest < ActiveSupport::TestCase

  include EvalTestHelper

  def test_employee_work_items_pascal
    @evaluation = EmployeeWorkItemsEval.new(employees(:pascal).id)
    assert ! @evaluation.absences?
    assert @evaluation.for?(employees(:pascal))
    assert @evaluation.total_details

    divisions = @evaluation.divisions.list.to_a
    assert_equal 2, divisions.size
    assert_equal work_items(:puzzle).id, divisions[0].id
    assert_equal work_items(:swisstopo).id, divisions[1].id

    assert_sum_times 0, 0, 2, 3, work_items(:puzzle)
    assert_sum_times 3, 3, 3, 3, work_items(:swisstopo)

    assert_equal({ work_items(:swisstopo).id => 3.0 },
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ work_items(:swisstopo).id => 3.0 },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ work_items(:puzzle).id => 2.0, work_items(:swisstopo).id => 3.0 },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times 3.0, 3.0, 5.0, 6.0
  end

  def test_employee_work_items_pascal_detail
    @evaluation = EmployeeSubWorkItemsEval.new(work_items(:puzzle).id, employees(:pascal).id)

    @evaluation.set_division_id(work_items(:allgemein).id)
    assert_sum_times 0, 0, 0, 1
    assert_count_times 0, 0, 0, 1

    @evaluation.set_division_id(work_items(:puzzletime).id)
    assert_sum_times 0, 0, 2, 2
    assert_count_times 0, 0, 1, 1
  end

  def test_employee_work_items_mark
    @evaluation = EmployeeWorkItemsEval.new(employees(:mark).id)
    assert ! @evaluation.absences?
    assert @evaluation.for?(employees(:mark))
    assert @evaluation.total_details

    divisions = @evaluation.divisions.list.to_a
    assert_equal 2, divisions.size
    assert_equal work_items(:puzzle).id, divisions[0].id
    assert_equal work_items(:swisstopo).id, divisions[1].id

    assert_sum_times 0, 11, 11, 11, work_items(:puzzle)
    assert_sum_times 0, 7, 7, 7, work_items(:swisstopo)

    assert_equal({},
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ work_items(:puzzle).id => 11.0, work_items(:swisstopo).id => 7.0 },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ work_items(:puzzle).id => 11.0, work_items(:swisstopo).id => 7.0 },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times 0.0, 18.0, 18.0, 18.0
  end

  def test_employee_work_items_mark_detail
    @evaluation = EmployeeSubWorkItemsEval.new(work_items(:puzzle).id, employees(:mark).id)
    @evaluation.set_division_id(work_items(:allgemein).id)
    assert_sum_times 0, 5, 5, 5
    assert_count_times 0, 1, 1, 1
  end

  def test_employee_work_items_lucien
    @evaluation = EmployeeWorkItemsEval.new(employees(:lucien).id)
    assert ! @evaluation.absences?
    assert @evaluation.for?(employees(:lucien))
    assert @evaluation.total_details

    divisions = @evaluation.divisions.list.to_a
    assert_equal 2, divisions.size
    assert_equal work_items(:puzzle).id, divisions[0].id
    assert_equal work_items(:swisstopo).id, divisions[1].id

    assert_sum_times 0, 9, 19, 19, work_items(:puzzle)
    assert_sum_times 0, 0, 11, 11, work_items(:swisstopo)

    assert_equal({},
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ work_items(:puzzle).id => 9.0 },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ work_items(:swisstopo).id => 11.0, work_items(:puzzle).id => 19.0 },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times 0.0, 9.0, 30.0, 30.0
  end

  def test_employee_work_items_lucien_detail
    @evaluation = EmployeeSubWorkItemsEval.new(work_items(:swisstopo).id, employees(:lucien).id)
    @evaluation.set_division_id(work_items(:webauftritt).id)
    assert_sum_times 0, 0, 11, 11
    assert_count_times 0, 0, 1, 1
  end

end