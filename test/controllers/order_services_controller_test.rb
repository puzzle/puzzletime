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

  test "GET show assigns tickets" do
    worktimes(:wt_pz_puzzletime).update!(ticket: 'foo')
    get :show, order_id: order.id
    assert_equal %w([leer] foo), assigns(:tickets)
  end

  test "GET show responds with success when no accounting posts present" do
    order.worktimes.destroy_all
    order.accounting_posts.destroy_all
    get :show, order_id: order.id
    assert_response :success
  end

  test "GET show filtered by predefined period, ignores start_date" do
    get :show, order_id: order.id, period: '-1m', start_date: '1.12.2006'
    assert_equal [], assigns(:worktimes)
    period = Period.parse('-1m')
    assert_equal period, assigns(:period)
    assert_equal({ "/orders/#{order.id}/order_services" =>
                   { 'start_date' => I18n.l(period.start_date),
                     'end_date' => I18n.l(period.end_date) } },
                  session[:list_params])
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

    test "GET #{action} filtered by period and employee" do
      get action, order_id: order.id, end_date: '10.12.2006', employee_id: employees(:pascal).id
      assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by ticket" do
      worktimes(:wt_pz_puzzletime).update!(ticket: 'foo')
      get action, order_id: order.id, ticket: 'foo'
      assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by empty ticket" do
      worktimes(:wt_pz_puzzletime).update!(ticket: 'foo')
      get action, order_id: order.id, ticket: '[leer]'
      assert_equal worktimes(:wt_mw_puzzletime, :wt_lw_puzzletime), assigns(:worktimes)
    end

    test "GET #{action} filtered by invoice" do
      invoice_id = invoices(:webauftritt_may).id
      worktimes(:wt_mw_webauftritt).update!(invoice_id: invoice_id)
      get action, order_id: orders(:webauftritt).id, invoice_id: invoice_id
      assert_equal [worktimes(:wt_mw_webauftritt)], assigns(:worktimes)
    end

    test "GET #{action} filtered by empty invoice" do
      invoice_id = invoices(:webauftritt_may).id
      worktimes(:wt_mw_webauftritt).update!(invoice_id: invoice_id)
      get action, order_id: orders(:webauftritt).id, invoice_id: '[leer]'
      assert_equal worktimes(:wt_pz_webauftritt, :wt_lw_webauftritt), assigns(:worktimes)
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

  test 'GET report contains all hours' do
    get :report, order_id: order.id

    assert_template 'report'
    total = assigns(:times).sum(:hours)
    assert_match /Total Stunden.*#{total}/m, response.body
  end

  test 'GET report contains all hours with combined tickets' do
    Worktime.where(employee_id: employees(:pascal).id).destroy_all
    Fabricate(:ordertime,
              employee: employees(:pascal),
              work_item: work_items(:puzzletime),
              ticket: 123)
    Fabricate(:ordertime,
              employee: employees(:pascal),
              work_item: work_items(:puzzletime),
              hours: 5)

    get :report, order_id: orders(:puzzletime).id,
                 employee_id: employees(:pascal),
                 combine_on: true,
                 combine: 'ticket'

    assert_template 'report'
    total = assigns(:times).sum(:hours)
    assert_equal 7, total
    assert_match /Total Stunden.*#{total}/m, response.body
  end

  test 'GET report with param show_ticket=1 shows tickets' do
    ticket_label = 'ticket-123'
    Fabricate(:ordertime,
              employee: employees(:pascal),
              work_item: work_items(:puzzletime),
              ticket: ticket_label)
    get :report, order_id: orders(:puzzletime).id,
                 show_ticket: "1"

    assert_template 'report'
    assert_match %r(<th>Ticket</th>), response.body
    assert_match %r(<td[^>]*>#{ticket_label}</td>), response.body
  end

  private

  def order
    orders(:puzzletime)
  end

end
