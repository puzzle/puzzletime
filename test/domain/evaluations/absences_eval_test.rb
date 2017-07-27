#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'
require_relative 'eval_test_helper'

class AbsencesEvalTest < ActiveSupport::TestCase

  include EvalTestHelper

  def setup
    super
    @evaluation = AbsencesEval.new
  end

  def test_absences
    assert @evaluation.absences?
    assert !@evaluation.for?(employees(:pascal))
    assert @evaluation.total_details

    divisions = @evaluation.divisions
    assert_equal 3, divisions.size

    assert_sum_times 0, 8, 8, 8, employees(:mark)
    assert_sum_times 0, 0, 12, 12, employees(:lucien)
    assert_sum_times 0, 4, 17, 17, employees(:pascal)

    assert_equal({},
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ employees(:mark).id => 8.0, employees(:pascal).id => 4.0 },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ employees(:mark).id => 8.0, employees(:lucien).id => 12.0, employees(:pascal).id => 17.0 },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times 0.0, 12.0, 37.0, 37.0
  end

  def test_absences_detail_mark
    @evaluation.set_division_id employees(:mark).id

    assert_sum_times 0, 8, 8, 8
    assert_count_times 0, 1, 1, 1
  end

  def test_absences_detail_lucien
    @evaluation.set_division_id employees(:lucien).id

    assert_sum_times 0, 0, 12, 12
    assert_count_times 0, 0, 1, 1
  end

  def test_absences_detail_pascal
    @evaluation.set_division_id employees(:pascal).id

    assert_sum_times 0, 4, 17, 17
    assert_count_times 0, 1, 2, 2
  end

end
