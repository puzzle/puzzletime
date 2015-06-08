# encoding: UTF-8

require 'test_helper'

class InvoicesControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  def test_update
    skip 'not implemented'
  end

  def test_update_json
    skip 'not implemented'
  end

  def test_destroy
    skip 'not implemented'
  end

  def test_create_json
    skip 'not implemented'
  end

  def test_create
    skip 'not implemented'
  end


  test 'GET new with params from order_services view filter assigns correct attributes' do
    login_as :mark
    get :new,
        order_id: test_entry.order_id,
        employee_id: employees(:pascal).id,
        work_item_id: work_items(:webauftritt).id,
        start_date: start_date = '01.12.2006',
        end_date: end_date = '31.12.2006'
    assert_response :success
    assert_template 'invoices/_form'
    assert_equal([employees(:pascal)], entry.employees)
    assert_equal([work_items(:webauftritt)], entry.work_items)
    assert_equal(Date.parse(start_date), entry.period_from)
    assert_equal(Date.parse(end_date), entry.period_to)
  end


  test 'all employees' do
    skip 'anpassen'
    assert_equal employees(:mark, :lucien, :pascal), builder.all_employees
  end

  test 'all accounting posts' do
    skip 'anpassen'
    assert_equal [accounting_posts(:webauftritt)], builder.all_accounting_posts
  end

  test 'build all positions' do
    skip 'anpassen'
    invoice.period_from = Date.new(2006, 1, 1)
    positions = builder.build_positions
    assert_equal 1, positions.size
    assert_equal 'Webauftritt', positions.first.name
    assert_equal 18, positions.first.total_hours
    assert_equal 18 * 140, positions.first.total_amount
  end

  test 'build all employees' do
    skip 'anpassen'
    builder.grouping = :employees
    invoice.period_from = Date.new(2006, 1, 1)
    positions = builder.build_positions
    assert_equal 2, positions.size
    assert_equal 'Webauftritt - Waber Mark', positions.first.name
    assert_equal 7, positions.first.total_hours
    assert_equal 7 * 140, positions.first.total_amount
    assert_equal 'Webauftritt - Weller Lucien', positions.last.name
    assert_equal 11, positions.last.total_hours
  end

  test 'build selected employees' do
    skip 'anpassen'
    builder.grouping = :employees
    builder.employees = employees(:mark)
    invoice.period_from = Date.new(2006, 1, 1)
    positions = builder.build_positions
    assert_equal 1, positions.size
    assert_equal 'Webauftritt - Waber Mark', positions.first.name
    assert_equal 7, positions.first.total_hours
    assert_equal 7 * 140, positions.first.total_amount
  end

  test 'save' do
    skip 'anpassen'
    Invoicing.instance = stub(:save_invoice)
    invoice.period_from = Date.new(2006, 1, 1)

    assert_equal true, builder.save

    invoice.reload
    assert_equal 18, invoice.total_hours
    assert_equal 18 * 140, invoice.total_amount
    assert_equal invoice.id, worktimes(:wt_mw_webauftritt).invoice_id
    assert_equal invoice.id, worktimes(:wt_lw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_pz_webauftritt).invoice_id
  end

  test 'save with validation error' do
    skip 'anpassen'
    Invoicing.instance = mock
    Invoicing.instance.expects(:save_invoice).never
    invoice.period_from = Date.new(2015, 12, 1)

    assert_equal false, builder.save
    assert_match /nach von/, invoice.errors.full_messages.join

    assert_equal nil, worktimes(:wt_mw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_lw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_pz_webauftritt).invoice_id
  end

  test 'save with exception' do
    skip 'anpassen'
    invoice.update!(total_hours: 0, total_amount: 0)
    Invoicing.instance = mock
    Invoicing.instance.expects(:save_invoice).raises(Invoicing::Error.new('No good'))
    invoice.period_from = Date.new(2006, 1, 1)

    assert_equal false, builder.save
    assert_equal 'No good', invoice.errors.full_messages.join

    invoice.reload
    assert_equal 0, invoice.total_hours
    assert_equal 0, invoice.total_amount
    assert_equal nil, worktimes(:wt_mw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_lw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_pz_webauftritt).invoice_id
  end

  test 'save manual' do
    skip 'anpassen'
    Invoicing.instance = stub(:save_invoice)
    invoice.period_from = Date.new(2006, 1, 1)
    builder.grouping = :manual

    assert_equal true, builder.save

    invoice.reload
    assert_equal 0, invoice.total_hours
    assert_equal 0, invoice.total_amount
    assert_equal nil, worktimes(:wt_mw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_lw_webauftritt).invoice_id
    assert_equal nil, worktimes(:wt_pz_webauftritt).invoice_id
  end

  private

  # Test object used in several tests.
  def test_entry
    invoices(:webauftritt_may)
  end
end
