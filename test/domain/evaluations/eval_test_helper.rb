#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module EvalTestHelper

  def setup
    @period_week = Period.new('4.12.2006', '10.12.2006')
    @period_month = Period.new('1.12.2006', '31.12.2006')
    @period_day = Period.new('4.12.2006', '4.12.2006')
  end

  private

  def assert_sum_times(day, week, month, all, div = nil)
    assert_equal day, @evaluation.sum_times(@period_day, div)
    assert_equal week, @evaluation.sum_times(@period_week, div)
    assert_equal month, @evaluation.sum_times(@period_month, div)
    assert_equal all, @evaluation.sum_times(nil, div)
  end

  def assert_sum_total_times(day, week, month, all)
    assert_equal day, @evaluation.sum_total_times(@period_day)
    assert_equal week, @evaluation.sum_total_times(@period_week)
    assert_equal month, @evaluation.sum_total_times(@period_month)
    assert_equal all, @evaluation.sum_total_times(nil)
  end

  def assert_sum_total_plannings(day, week, month, all)
    assert_equal day, @evaluation.sum_total_plannings(@period_day)
    assert_equal week, @evaluation.sum_total_plannings(@period_week)
    assert_equal month, @evaluation.sum_total_plannings(@period_month)
    assert_equal all, @evaluation.sum_total_plannings(nil)
  end

  def assert_count_times(day, week, month, all)
    assert_equal day, @evaluation.times(@period_day).size
    assert_equal week, @evaluation.times(@period_week).size
    assert_equal month, @evaluation.times(@period_month).size
    assert_equal all, @evaluation.times(nil).size
  end
  

end