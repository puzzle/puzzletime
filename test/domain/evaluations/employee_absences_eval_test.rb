#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require_relative 'eval_test_helper'

class EmployeeAbsencesEvalTest < ActiveSupport::TestCase
  include EvalTestHelper

  def test_employee_absences_pascal
    @evaluation = EmployeeAbsencesEval.new(employees(:pascal).id)
    assert @evaluation.absences?
    assert @evaluation.for?(employees(:pascal))
    assert @evaluation.total_details

    divisions = @evaluation.divisions.list
    assert_equal 2, divisions.size
    assert_equal absences(:doctor), divisions[0]
    assert_equal absences(:vacation), divisions[1]

    assert_sum_times 0, 4, 17, 17
    assert_sum_times 0, 4, 4, 4, absences(:vacation)
    assert_sum_times 0, 0, 13, 13, absences(:doctor)

    assert_equal({},
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ absences(:vacation).id => 4.0 },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ absences(:vacation).id => 4.0, absences(:doctor).id => 13.0 },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times 0.0, 4.0, 17.0, 17.0
  end

  def test_employee_absences_pascal_detail
    @evaluation = EmployeeAbsencesEval.new(employees(:pascal).id)

    @evaluation.set_division_id(absences(:vacation).id)
    assert_sum_times 0, 4, 4, 4
    assert_count_times 0, 1, 1, 1

    @evaluation.set_division_id(absences(:doctor).id)
    assert_sum_times 0, 0, 13, 13
    assert_count_times 0, 0, 1, 1
  end

  def test_employee_absences_mark
    @evaluation = EmployeeAbsencesEval.new(employees(:mark).id)
    assert @evaluation.absences?
    assert @evaluation.for?(employees(:mark))
    assert @evaluation.total_details

    divisions = @evaluation.divisions.list
    assert_equal 1, divisions.size
    assert_equal absences(:civil_service), divisions[0]

    assert_sum_times 0, 8, 8, 8
    assert_sum_times 0, 8, 8, 8, absences(:civil_service)

    assert_equal({},
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ absences(:civil_service).id => 8.0 },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ absences(:civil_service).id => 8.0 },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times 0.0, 8.0, 8.0, 8.0
  end

  def test_employee_absences_mark_detail
    @evaluation = EmployeeAbsencesEval.new(employees(:mark).id)

    @evaluation.set_division_id(absences(:civil_service).id)
    assert_sum_times 0, 8, 8, 8
    assert_count_times 0, 1, 1, 1
  end

  def test_employee_absences_lucien
    @evaluation = EmployeeAbsencesEval.new(employees(:lucien).id)
    assert @evaluation.absences?
    assert @evaluation.for?(employees(:lucien))
    assert @evaluation.total_details

    divisions = @evaluation.divisions.list
    assert_equal 1, divisions.size
    assert_equal absences(:doctor), divisions[0]

    assert_sum_times 0, 0, 12, 12
    assert_sum_times 0, 0, 12, 12, absences(:doctor)

    assert_equal({},
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({},
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ absences(:doctor).id => 12.0 },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times 0.0, 0.0, 12.0, 12.0
  end

  def test_employee_absences_lucien_detail
    @evaluation = EmployeeAbsencesEval.new(employees(:lucien).id)

    @evaluation.set_division_id(absences(:doctor).id)
    assert_sum_times 0, 0, 12, 12
    assert_count_times 0, 0, 1, 1
  end

  def test_sum_times_search_conditions
    period = Period.new(Date.parse('2006-01-01'), Date.parse('2006-12-31'))
    assert_equal(worktimes(:wt_pz_vacation, :wt_pz_doctor), EmployeeAbsencesEval.new(employees(:pascal).id).times(period))
    assert_equal([worktimes(:wt_pz_vacation)], EmployeeAbsencesEval.new(employees(:pascal).id, absence_id: absences(:vacation).id).times(period))
    assert_equal([worktimes(:wt_pz_doctor)], EmployeeAbsencesEval.new(employees(:pascal).id, absence_id: absences(:doctor).id).times(period))
    assert_equal([], EmployeeAbsencesEval.new(employees(:pascal).id, absence_id: absences(:civil_service).id).times(period))
  end
end
