#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require_relative 'eval_test_helper'

class Evaluations::ClientsEvalTest < ActiveSupport::TestCase
  include EvalTestHelper

  def setup
    super
    @evaluation = Evaluations::ClientsEval.new
  end

  def test_clients
    assert_not @evaluation.absences?
    assert_not @evaluation.for?(employees(:pascal))
    assert_not @evaluation.total_details

    divisions = @evaluation.divisions.list

    assert_equal 3, divisions.size
    assert_equal work_items(:pbs), divisions[0]
    assert_equal work_items(:puzzle), divisions[1]
    assert_equal work_items(:swisstopo), divisions[2]

    assert_sum_times 0, 20, 32, 33, work_items(:puzzle)
    assert_sum_times 3, 10, 21, 21, work_items(:swisstopo)

    assert_equal({ work_items(:swisstopo).id => { hours: 3.0, billable_hours: 0.0 } },
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ work_items(:puzzle).id => { hours: 20.0, billable_hours: 20.0 },
                   work_items(:swisstopo).id => { hours: 10.0, billable_hours: 7.0 } },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ work_items(:puzzle).id => { hours: 32.0, billable_hours: 22.0 },
                   work_items(:swisstopo).id => { hours: 21.0, billable_hours: 18.0 } },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times({ hours: 3.0, billable_hours: 0.0 },
                           { hours: 30.0, billable_hours: 27.0 },
                           { hours: 53.0, billable_hours: 40.0 },
                           { hours: 54.0, billable_hours: 41.0 })
  end

  def test_clients_detail_puzzle
    @evaluation.set_division_id work_items(:puzzle).id

    assert_sum_times 0, 20, 32, 33
    assert_count_times 0, 3, 5, 6
  end

  def test_clients_detail_swisstopo
    @evaluation.set_division_id work_items(:swisstopo).id

    assert_sum_times 3, 10, 21, 21
    assert_count_times 1, 2, 3, 3
  end
end
