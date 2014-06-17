require 'test_helper'

# Test UtilityHelper
class WorktimeHelperTest < ActionView::TestCase
  def setup
    @worktimes = Worktime.where('employee_id = ? AND work_date >= ? AND work_date <= ?', 7, Date.new(2006, 12, 4), Date.new(2006, 12, 10))
  end

  test 'daily worktimes' do
    assert_equal [worktimes(:wt_mw_webauftritt)], daily_worktimes(@worktimes, Date.new(2006, 12, 8))
  end
  
  test 'sum daily worktimes' do
    assert_equal 8, sum_daily_worktimes(@worktimes, Date.new(2006, 12, 9))
  end
  
  test 'sum total worktimes' do
    assert_equal 26, sum_total_worktimes(@worktimes)
  end

end
