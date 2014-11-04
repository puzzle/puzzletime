require 'test_helper'

class OrderServicesControllerTest < ActionController::TestCase

  setup :login

  test 'GET show assigns order employees' do
    get :show, order_id: order.id
    assert_equal employees(:mark, :lucien, :pascal), assigns(:employees)
  end

  test 'GET show assigns order accounting posts' do
    get :show, order_id: orders(:hitobito_demo).id
    assert_equal work_items(:hitobito_demo_app, :hitobito_demo_site), assigns(:accounting_posts)
  end

  test 'GET show filtered by employee' do
    get :show, order_id: order.id, employee_id: employees(:pascal).id
    assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
  end

  test 'GET show filtered by accounting post' do
    get :show, order_id: order.id, work_item_id: work_items(:puzzletime).id
    assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime, :wt_lw_puzzletime), assigns(:worktimes)
  end

  test 'GET show filtered by billable' do
    get :show, order_id: order.id, billable: 'true'
    assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime), assigns(:worktimes)
  end

  test 'GET show filtered by not billable' do
    get :show, order_id: order.id, billable: 'false'
    assert_equal [worktimes(:wt_lw_puzzletime)], assigns(:worktimes)
  end

  test 'GET show filtered by employee and billable' do
    get :show, order_id: order.id, employee_id: employees(:pascal), billable: 'false'
    assert_equal [], assigns(:worktimes)
  end

  test 'GET show filtered by employee, accounting post and billable' do
    get :show, order_id: order.id,
               employee_id: employees(:pascal),
               work_item_id: work_items(:puzzletime).id,
               billable: 'true'
    assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
  end

  private

  def order
    orders(:puzzletime)
  end

end
