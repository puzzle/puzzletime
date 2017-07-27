#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'
require_relative 'eval_test_helper'

class ManagedOrdersEvalTest < ActiveSupport::TestCase

  include EvalTestHelper

  def test_managed_work_items_pascal
    @evaluation = ManagedOrdersEval.new(employees(:pascal))
    assert_managed employees(:pascal)

    divisions = @evaluation.divisions.list
    assert_equal 0, divisions.size
  end

  def test_managed_work_items_mark
    @evaluation = ManagedOrdersEval.new(employees(:mark))
    assert_managed employees(:mark)

    divisions = @evaluation.divisions.list
    assert_equal 1, divisions.size
    assert_equal work_items(:allgemein).id, divisions.first.id

    assert_sum_times 0, 14, 14, 15, work_items(:allgemein)

    assert_equal({},
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ work_items(:allgemein).id => { hours: 14.0, billable_hours: 14.0 } },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ work_items(:allgemein).id => { hours: 14.0, billable_hours: 14.0 } },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times({ hours: 0.0, billable_hours: 0.0 },
                           { hours: 14.0, billable_hours: 14.0 },
                           { hours: 14.0, billable_hours: 14.0 },
                           { hours: 15.0, billable_hours: 15.0 })
  end

  def test_managed_work_item_plannings_mark
    @evaluation = ManagedOrdersEval.new(employees(:mark))

    Fabricate(:planning, work_item: work_items(:allgemein), date: '2006-12-05', percent: 100)
    Fabricate(:planning, work_item: work_items(:allgemein), date: '2006-12-06', percent: 100)
    Fabricate(:planning, work_item: work_items(:allgemein), date: '2006-12-14', percent: 50)
    Fabricate(:planning, work_item: work_items(:puzzletime), date: '2006-12-04', percent: 100)

    assert_equal({},
                 @evaluation.sum_plannings_grouped(@period_day))
    assert_equal({ work_items(:allgemein).id => { hours: 16.0, billable_hours: 16.0 } },
                 @evaluation.sum_plannings_grouped(@period_week))
    assert_equal({ work_items(:allgemein).id => { hours: 20.0, billable_hours: 20.0 } },
                 @evaluation.sum_plannings_grouped(@period_month))

    assert_sum_total_plannings({ hours: 0.0, billable_hours: 0.0 },
                               { hours: 16.0, billable_hours: 16.0 },
                               { hours: 20.0, billable_hours: 20.0 },
                               { hours: 20.0, billable_hours: 20.0 })
  end

  def test_managed_work_items_mark_details
    @evaluation = ManagedOrdersEval.new(employees(:mark))
    @evaluation.set_division_id work_items(:allgemein).id

    assert_sum_times 0, 14, 14, 15
    assert_count_times 0, 2, 2, 3
  end

  def test_managed_work_items_lucien
    @evaluation = ManagedOrdersEval.new(employees(:lucien))
    assert_managed employees(:lucien)
    divisions = @evaluation.divisions
    assert_equal 2, divisions.size
    assert_equal work_items(:hitobito_demo).id, divisions[0].id
    assert_equal work_items(:puzzletime).id, divisions[1].id

    assert_sum_times 0, 6, 18, 18, work_items(:puzzletime)

    assert_equal({},
                 @evaluation.sum_times_grouped(@period_day))
    assert_equal({ work_items(:puzzletime).id => { hours: 6.0, billable_hours: 6.0 } },
                 @evaluation.sum_times_grouped(@period_week))
    assert_equal({ work_items(:puzzletime).id => { hours: 18.0, billable_hours: 8.0 } },
                 @evaluation.sum_times_grouped(@period_month))

    assert_sum_total_times({ hours: 0.0, billable_hours: 0.0 },
                           { hours: 6.0, billable_hours: 6.0 },
                           { hours: 18.0, billable_hours: 8.0 },
                           { hours: 18.0, billable_hours: 8.0 })
  end

  def test_managed_work_items_lucien_details
    @evaluation = ManagedOrdersEval.new(employees(:lucien))
    @evaluation.set_division_id work_items(:puzzletime).id

    assert_sum_times 0, 6, 18, 18
    assert_count_times 0, 1, 3, 3
  end

  def assert_managed(user)
    assert ! @evaluation.absences?
    assert ! @evaluation.for?(user)
    assert ! @evaluation.total_details
  end

end