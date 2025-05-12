# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class OrderServicesControllerTest < ActionController::TestCase
  setup :login

  test 'GET show assigns order employees' do
    get :show, params: { order_id: order.id }

    assert_equal employees(:mark, :lucien, :pascal), assigns(:employees)
  end

  test 'GET show assigns order accounting posts' do
    Ordertime.create!(employee: employees(:pascal),
                      work_item: work_items(:hitobito_demo_app),
                      work_date: '1.5.2016',
                      hours: 2,
                      report_type: 'absolute_day')
    Ordertime.create!(employee: employees(:lucien),
                      work_item: work_items(:hitobito_demo_site),
                      work_date: '6.6.2016',
                      hours: 4,
                      report_type: 'absolute_day')
    get :show, params: { order_id: orders(:hitobito_demo).id }

    assert_equal work_items(:hitobito_demo_app, :hitobito_demo_site), assigns(:accounting_posts)
  end

  test 'GET show assigns employees and accounting_posts based on period' do
    Ordertime.create!(employee: employees(:pascal),
                      work_item: work_items(:hitobito_demo_app),
                      work_date: '1.5.2016',
                      hours: 2,
                      report_type: 'absolute_day')
    Ordertime.create!(employee: employees(:lucien),
                      work_item: work_items(:hitobito_demo_site),
                      work_date: '6.6.2016',
                      hours: 4,
                      report_type: 'absolute_day')
    get :show, params: { order_id: orders(:hitobito_demo).id, start_date: '1.5.2016', end_date: '1.6.2016' }

    assert_equal [work_items(:hitobito_demo_app)], assigns(:accounting_posts)
    assert_equal [employees(:pascal)], assigns(:employees)
  end

  test 'GET show assigns tickets' do
    worktimes(:wt_pz_puzzletime).update!(ticket: 'foo')
    get :show, params: { order_id: order.id }

    assert_equal %w([leer] foo), assigns(:tickets)
  end

  test 'GET show responds with success when no accounting posts present' do
    order.worktimes.destroy_all
    order.accounting_posts.destroy_all
    get :show, params: { order_id: order.id }

    assert_response :success
  end

  test 'GET show filtered by predefined period, ignores start_date' do
    get :show, params: { order_id: order.id, period_shortcut: '-1m', start_date: '1.12.2006' }

    assert_empty assigns(:worktimes)
    period = Period.parse('-1m')

    assert_equal period, assigns(:period)
    assert_equal({ "/orders/#{order.id}/order_services" =>
                     { 'period_shortcut' => '-1m', 'start_date' => '1.12.2006' } },
                 session[:list_params])
  end

  %i[show export_worktimes_csv report].each do |action|
    test "GET #{action} filtered by employee" do
      get action, params: { order_id: order.id, employee_id: employees(:pascal).id }

      assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by accounting post" do
      get action, params: { order_id: order.id, work_item_id: work_items(:puzzletime).id }

      assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime, :wt_lw_puzzletime), assigns(:worktimes)
    end

    test "GET #{action} filtered by billable" do
      get action, params: { order_id: order.id, billable: 'true' }

      assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime), assigns(:worktimes)
    end

    test "GET #{action} filtered by not billable" do
      get action, params: { order_id: order.id, billable: 'false' }

      assert_equal [worktimes(:wt_lw_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by employee and billable" do
      get action, params: { order_id: order.id, employee_id: employees(:pascal), billable: 'false' }

      assert_empty assigns(:worktimes)
    end

    test "GET #{action} filtered by employee, accounting post and billable" do
      get action, params: {
        order_id: order.id,
        employee_id: employees(:pascal),
        work_item_id: work_items(:puzzletime).id,
        billable: 'true'
      }

      assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by period open end" do
      get action, params: { order_id: order.id, start_date: '10.12.2006' }

      assert_equal [worktimes(:wt_lw_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by period open start" do
      get action, params: { order_id: order.id, end_date: '10.12.2006' }

      assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime), assigns(:worktimes)
    end

    test "GET #{action} filtered by period with start and end" do
      get action, params: { order_id: order.id, start_date: '5.12.2006', end_date: '10.12.2006' }

      assert_equal [worktimes(:wt_mw_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by period and employee" do
      get action, params: { order_id: order.id, end_date: '10.12.2006', employee_id: employees(:pascal).id }

      assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by ticket" do
      worktimes(:wt_pz_puzzletime).update!(ticket: 'foo')
      get action, params: { order_id: order.id, ticket: 'foo' }

      assert_equal [worktimes(:wt_pz_puzzletime)], assigns(:worktimes)
    end

    test "GET #{action} filtered by empty ticket" do
      worktimes(:wt_pz_puzzletime).update!(ticket: 'foo')
      get action, params: { order_id: order.id, ticket: '[leer]' }

      assert_equal worktimes(:wt_mw_puzzletime, :wt_lw_puzzletime), assigns(:worktimes)
    end

    test "GET #{action} filtered by invoice" do
      invoice_id = invoices(:webauftritt_may).id
      worktimes(:wt_mw_webauftritt).update!(invoice_id:)
      get action, params: { order_id: orders(:webauftritt).id, invoice_id: }

      assert_equal [worktimes(:wt_mw_webauftritt)], assigns(:worktimes)
    end

    test "GET #{action} filtered by empty invoice" do
      invoice_id = invoices(:webauftritt_may).id
      worktimes(:wt_mw_webauftritt).update!(invoice_id:)
      get action, params: { order_id: orders(:webauftritt).id, invoice_id: '[leer]' }

      assert_equal worktimes(:wt_pz_webauftritt, :wt_lw_webauftritt), assigns(:worktimes)
    end

    test "GET #{action} filtered by invalid start date" do
      get action, params: { order_id: order.id, start_date: 'abc' }

      assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime, :wt_lw_puzzletime), assigns(:worktimes)
      assert_match(/ungültig/i, flash[:alert])
      assert_equal Period.new(nil, nil), assigns(:period)
    end

    test "GET #{action} filtered by start date after end date" do
      get action, params: { order_id: order.id, start_date: '1.12.2006', end_date: '1.1.2006' }

      assert_equal worktimes(:wt_pz_puzzletime, :wt_mw_puzzletime, :wt_lw_puzzletime), assigns(:worktimes)
      assert_match(/ungültig/i, flash[:alert])
      assert_equal Period.new(nil, nil), assigns(:period)
    end
  end

  test 'GET report contains hours of the selected accounting post' do
    Fabricate(:ordertime,
              work_date: '2024-01-01',
              employee: employees(:pascal),
              work_item: work_items(:hitobito_demo_site),
              ticket: 123,
              hours: 10,
              billable: true)
    Fabricate(:ordertime,
              work_date: '2024-01-01',
              employee: employees(:pascal),
              work_item: work_items(:hitobito_demo_app),
              ticket: 123,
              hours: 3,
              billable: true)

    get :report, params: { order_id: orders(:hitobito_demo).id, work_item_ids: [work_items(:hitobito_demo_app).id] }
    total = accounting_posts(:hitobito_demo_app).worktimes.sum(&:hours)

    assert_match(/Total Stunden.*#{total}/m, response.body)
  end
  test 'GET report contains hours of all accounting posts, even if no specific accounting_post is specified' do
    Fabricate(:ordertime,
              work_date: '2024-01-01',
              employee: employees(:pascal),
              work_item: work_items(:hitobito_demo_site),
              ticket: 123,
              hours: 10,
              billable: true)
    Fabricate(:ordertime,
              work_date: '2024-01-01',
              employee: employees(:pascal),
              work_item: work_items(:hitobito_demo_app),
              ticket: 123,
              hours: 3,
              billable: true)

    get :report, params: { order_id: orders(:hitobito_demo).id }
    total = orders(:hitobito_demo).accounting_posts.flat_map(&:worktimes).sum(&:hours)

    assert_match(/Total Stunden.*#{total}/m, response.body)
  end

  test 'GET report with invoice_id gets all hours and sets period' do
    invoice = invoices(:webauftritt_may)
    worktimes(:wt_mw_webauftritt).update!(invoice_id: invoice.id, work_date: invoice.period_from - 2.days)
    get :report, params: { order_id: orders(:webauftritt).id, invoice_id: invoice.id }

    assert_equal [worktimes(:wt_mw_webauftritt)], assigns(:worktimes)
    assert_equal invoice.period_from, assigns(:period).start_date
    assert_equal invoice.period_to, assigns(:period).end_date
  end

  test 'GET report with invoice_id gets only hours in defined period' do
    invoice = invoices(:webauftritt_may)
    worktimes(:wt_mw_webauftritt).update!(invoice_id: invoice.id, work_date: invoice.period_from)
    get :report, params: { order_id: orders(:webauftritt).id, invoice_id: invoice.id, start_date: '2006-12-15' }

    assert_empty assigns(:worktimes)
    assert_equal Date.parse('2006-12-15'), assigns(:period).start_date
    assert_nil assigns(:period).end_date
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

    get :report, params: {
      order_id: orders(:puzzletime).id,
      employee_id: employees(:pascal),
      combine_on: true,
      combine: 'ticket'
    }

    assert_template 'report'
    total = assigns(:worktimes).sum(:hours)

    assert_equal 7, total
    assert_match(/Total Stunden.*#{total}/m, response.body)
  end

  test 'GET report with param show_ticket=1 shows tickets' do
    ticket_label = 'ticket-123'
    Fabricate(:ordertime,
              employee: employees(:pascal),
              work_item: work_items(:puzzletime),
              ticket: ticket_label)
    get :report, params: {
      order_id: orders(:puzzletime).id,
      show_ticket: '1'
    }

    assert_template 'report'
    assert_match %r{<th class='right'>Ticket</th>}, response.body
    assert_match %r{<td[^>]*>#{ticket_label}</td>}, response.body
  end

  test 'GET report renders checkboxes for entries not associated with sent/paid invoice' do
    Worktime.where(work_item_id: work_items(:puzzletime).id).destroy_all
    o1 = Fabricate(:ordertime,
                   employee: employees(:pascal),
                   work_item: work_items(:puzzletime),
                   hours: 1)
    o2 = Fabricate(:ordertime,
                   employee: employees(:pascal),
                   work_item: work_items(:puzzletime),
                   invoice: create_invoice('draft'),
                   hours: 1)
    o3 = Fabricate(:ordertime,
                   employee: employees(:pascal),
                   work_item: work_items(:puzzletime),
                   invoice: create_invoice('sent'),
                   hours: 2)
    o4 = Fabricate(:ordertime,
                   employee: employees(:pascal),
                   work_item: work_items(:puzzletime),
                   invoice: create_invoice('paid'),
                   hours: 3)
    o5 = Fabricate(:ordertime,
                   employee: employees(:pascal),
                   work_item: work_items(:puzzletime),
                   invoice: create_invoice('partially_paid'),
                   hours: 4)

    get :show, params: { order_id: order.id }

    assert_select "input[type=\"checkbox\"][value=\"#{o1.id}\"]", count: 1
    assert_select "input[type=\"checkbox\"][value=\"#{o2.id}\"]", count: 1
    assert_select "input[type=\"checkbox\"][value=\"#{o3.id}\"]", count: 0
    assert_select "input[type=\"checkbox\"][value=\"#{o4.id}\"]", count: 0
    assert_select "input[type=\"checkbox\"][value=\"#{o5.id}\"]", count: 0
  end

  private

  def create_invoice(status)
    Fabricate(:invoice, order:, status:, due_date: Date.new(2000, 1, 23))
  end

  def order
    orders(:puzzletime)
  end
end
