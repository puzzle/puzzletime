#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require_relative 'eval_test_helper'

class ClientWorkItemsEvalTest < ActiveSupport::TestCase
  include EvalTestHelper

  def test_client_work_items
    @evaluation = ClientWorkItemsEval.new(clients(:puzzle).id)
    assert !@evaluation.absences?
    assert !@evaluation.for?(employees(:mark))
    assert @evaluation.total_details

    divisions = @evaluation.divisions.list
    assert_equal 4, divisions.size
    assert_equal work_items(:allgemein), divisions[0]
    assert_equal work_items(:hitobito), divisions[1]
    assert_equal work_items(:intern), divisions[2]
    assert_equal work_items(:puzzletime), divisions[3]

    assert_sum_times 0, 20, 32, 33
    assert_count_times 0, 3, 5, 6
    assert_sum_times 0, 14, 14, 15, work_items(:allgemein)
    assert_sum_times 0, 6, 18, 18, work_items(:puzzletime)

    assert_equal({},
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ work_items(:allgemein).id => { hours: 14.0, billable_hours: 14.0 },
                   work_items(:puzzletime).id => { hours: 6.0, billable_hours: 6.0 } },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ work_items(:allgemein).id => { hours: 14.0, billable_hours: 14.0 },
                   work_items(:puzzletime).id => { hours: 18.0, billable_hours: 8.0 } },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times({ hours: 0.0, billable_hours: 0.0 },
                           { hours: 20.0, billable_hours: 20.0 },
                           { hours: 32.0, billable_hours: 22.0 },
                           { hours: 33.0, billable_hours: 23.0 })
  end

  def test_client_work_items_detail
    @evaluation = ClientWorkItemsEval.new(clients(:puzzle).id)

    @evaluation.set_division_id(work_items(:allgemein).id)
    assert_sum_times 0, 14, 14, 15
    assert_count_times 0, 2, 2, 3

    @evaluation.set_division_id(work_items(:puzzletime).id)
    assert_sum_times 0, 6, 18, 18
    assert_count_times 0, 1, 3, 3
  end
end
