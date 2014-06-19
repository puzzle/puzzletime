require 'test_helper'

class WorktimesControllerTest < ActionController::TestCase
  
  setup :login
  
  def test_index
    get :index
    assert_equal 7, assigns(:week_days).count
    assert_equal Date.today.at_beginning_of_week, assigns(:week_days).first
    assert_equal Date.today.at_end_of_week, assigns(:week_days).last
  end
  
  def test_week_switcher
    get :index, week_date: '2013-12-31' 
    assert_equal 7, assigns(:week_days).count
    assert_equal Date.new(2013, 12, 30), assigns(:week_days).first
    assert_equal Date.new(2014, 1, 5), assigns(:week_days).last
  end

  def test_date_picker_week_switcher
    get :index, week_date: '31.12.2013' #datepicker uses german locale 
    assert_equal 7, assigns(:week_days).count
    assert_equal Date.new(2013, 12, 30), assigns(:week_days).first
    assert_equal Date.new(2014, 1, 5), assigns(:week_days).last
  end

  
  def test_worktimes
    get :index, week_date: '2006-12-8'
    assert_equal 4, assigns(:worktimes).count
    assert_equal Date.new(2006, 12, 6), assigns(:worktimes).first.work_date
    assert_equal Date.new(2006, 12, 9), assigns(:worktimes).last.work_date
  end

end
