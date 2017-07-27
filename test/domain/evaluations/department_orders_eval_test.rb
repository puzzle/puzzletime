#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'
require_relative 'eval_test_helper'

class DepartmentOrdersEvalTest < ActiveSupport::TestCase

  include EvalTestHelper

  def setup
    super
    @evaluation = DepartmentOrdersEval.new(department.id)
  end

  test 'plannings' do
    Fabricate(:planning, work_item: work_items(:webauftritt), date: '2006-12-05',
              percent: 100, definitive: true)
    Fabricate(:planning, work_item: work_items(:webauftritt), date: '2006-12-06',
              percent: 100, definitive: true)
    Fabricate(:planning, work_item: work_items(:webauftritt), date: '2006-12-14',
              percent: 50, definitive: true)
    Fabricate(:planning, work_item: work_items(:puzzletime), date: '2006-12-04',
              percent: 100, definitive: true)
    Fabricate(:planning, work_item: work_items(:puzzletime), date: '2006-12-05',
              percent: 75, definitive: true)
    Fabricate(:planning, work_item: work_items(:puzzletime), date: '2006-11-01',
              percent: 100, definitive: true)
    Fabricate(:planning, work_item: work_items(:allgemein), date: '2006-12-04',
              percent: 100, definitive: true)
    Fabricate(:planning, work_item: work_items(:puzzletime), date: '2006-11-02',
              percent: 80, definitive: false) # provisional (ignored)

    assert_equal({ work_items(:puzzletime).id => { hours: 8.0, billable_hours: 0.0 } },
                 @evaluation.sum_plannings_grouped(@period_day))
    assert_equal({ work_items(:webauftritt).id => { hours: 16.0, billable_hours: 16.0 },
                   work_items(:puzzletime).id => { hours: 14.0, billable_hours: 0.0 }},
                 @evaluation.sum_plannings_grouped(@period_week))
    assert_equal({ work_items(:webauftritt).id => { hours: 20.0, billable_hours: 20.0 },
                   work_items(:puzzletime).id => { hours: 14.0, billable_hours: 0.0 } },
                 @evaluation.sum_plannings_grouped(@period_month))

    assert_sum_total_plannings({ hours: 8.0, billable_hours: 0.0 },
                               { hours: 30.0, billable_hours: 16.0 },
                               { hours: 34.0, billable_hours: 20.0 },
                               { hours: 42.0, billable_hours: 20.0 })
  end

  test 'adds completed supplement' do
    supplement = @evaluation.division_supplement(employees(:mark))
    assert_equal 2, supplement.length
    assert_equal :order_completed, supplement.first.first
  end

  private

  def department
    departments(:devone)
  end

end
