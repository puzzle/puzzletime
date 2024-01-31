#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require_relative 'eval_test_helper'

class Evaluations::EmployeesEvalTest < ActiveSupport::TestCase
  include EvalTestHelper

  def setup
    super
    @evaluation = Evaluations::EmployeesEval.new
  end

  def test_employees
    assert !@evaluation.absences?
    assert !@evaluation.for?(employees(:pascal))
    assert !@evaluation.total_details

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
    @evaluation = Evaluations::EmployeesEval.new(departments(:devtwo).id)

    assert_sum_total_times 3.0, 12.0, 35.0, 36.0
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
end
