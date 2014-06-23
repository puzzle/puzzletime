require 'test_helper'

# Test UtilityHelper
class WorktimeHelperTest < ActionView::TestCase
  include FormatHelper

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

  test 'worktime account' do
    worktime = Absencetime.new(account_id: absences(:vacation).id)
    assert_equal 'Ferien', worktime_account(worktime)
  end

  def worktime_account(worktime)
    worktime.account.label_verbose if worktime.account
  end

  test 'worktime description with ticket' do
    worktime = Worktime.new(description: 'desc', ticket: '123')
    assert_equal "123 - desc", worktime_description(worktime)
  end

  test 'worktime description without ticket' do
    worktime = Worktime.new(description: 'desc')
    assert_equal "desc", worktime_description(worktime)
  end

  test 'holiday time class' do
    assert_equal "holiday", overview_day_class(@worktimes, Date.new(2014, 06, 9)) #pfingstmontag
  end

  test 'missing time class' do
    assert_equal "missing", overview_day_class(@worktimes, Date.new(1990, 6, 13))
  end

  test 'normal time class' do
    assert_equal nil, overview_day_class(@worktimes, Date.new(2040, 6, 15))
  end

  test 'time range without' do
    worktime = Worktime.new(from_start_time: '8:00', to_end_time: '11:59')
    assert_equal "08:00 - 11:59", time_range(worktime)
  end

  test 'time range without any times' do
    worktime = Worktime.new
    assert_equal "", time_range(worktime)
  end

  test 'time range without end time' do
    worktime = Worktime.new(from_start_time: '8:00')
    assert_equal "08:00 - ", time_range(worktime)
  end

end
