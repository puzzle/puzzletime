# encoding: utf-8

require 'test_helper'

class OrderServicesControllerTest < ActionController::TestCase

  setup :login

  test "GET show assigns order employees" do
    get :show, order_id: order.id
    assert_equal employees(:mark, :lucien, :pascal), assigns(:employees)
  end

  test "GET show assigns order accounting posts" do
    get :show, order_id: orders(:hitobito_demo).id
    assert_equal work_items(:hitobito_demo_app, :hitobito_demo_site), assigns(:accounting_posts)
  end

  [:show, :export_worktimes_csv].each do |action|

    test "GET #{action} filtered by employee" do
      get action, order_id: order.id, employee_id: employees(:pascal).id
      assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by accounting post" do
      get action, order_id: order.id, work_item_id: work_items(:puzzletime).id
      assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime, :wt_lw_puzzletime), assigns(:worktimes)
    end

    test "GET #{action} filtered by billable" do
      get action, order_id: order.id, billable: 'true'
      assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime), assigns(:worktimes)
    end

    test "GET #{action} filtered by not billable" do
      get action, order_id: order.id, billable: 'false'
      assert_equal [worktimes(:wt_lw_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by employee and billable" do
      get action, order_id: order.id, employee_id: employees(:pascal), billable: 'false'
      assert_equal [], assigns(:worktimes)
    end

    test "GET #{action} filtered by employee, accounting post and billable" do
      get action, order_id: order.id,
                 employee_id: employees(:pascal),
                 work_item_id: work_items(:puzzletime).id,
                 billable: 'true'
      assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by period open end" do
      get action, order_id: order.id, start_date: '10.12.2006'
      assert_equal [worktimes(:wt_lw_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by period open start" do
      get action, order_id: order.id, end_date: '10.12.2006'
      assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime), assigns(:worktimes)
    end

    test "GET #{action} filtered by period with start and end" do
      get action, order_id: order.id, start_date: '5.12.2006', end_date: '10.12.2006'
      assert_equal [worktimes(:wt_mw_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by predefined period, ignores start_date" do
      get action, order_id: order.id, period: '-1m', start_date: '1.12.2006'
      assert_equal [], assigns(:worktimes)
      assert_equal Period.parse('-1m'), assigns(:period)
    end

    test "GET #{action} filtered by period and employee" do
      get action, order_id: order.id, end_date: '10.12.2006', employee_id: employees(:pascal).id
      assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by invalid start date" do
      get action, order_id: order.id, start_date: 'abc'
      assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime, :wt_lw_puzzletime), assigns(:worktimes)
      assert_match /ungültig/i, flash[:alert]
      assert_equal Period.retrieve(nil, nil), assigns(:period)
    end

    test "GET #{action} filtered by start date after end date" do
      get action, order_id: order.id, start_date: '1.12.2006', end_date: '1.1.2006'
      assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime, :wt_lw_puzzletime), assigns(:worktimes)
      assert_match /ungültig/i, flash[:alert]
      assert_equal Period.retrieve(nil, nil), assigns(:period)
    end
  end

  private

  def order
    orders(:puzzletime)
  end

end
