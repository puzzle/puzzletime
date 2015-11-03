# encoding: UTF-8

require 'test_helper'

class InvoicesControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup { Invoicing.instance = nil }
  setup :login

  def test_show_with_non_existing_id_raises_record_not_found
    # we redirect to allow order changes with dropdown
    get :show, id: 42, order_id: test_entry.order_id
    assert_redirected_to order_invoices_path(test_entry.order_id)
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

  test 'GET new without params sets defaults' do
    worktimes(:wt_pz_webauftritt).update!(billable: true)
    get :new, order_id: test_entry.order_id
    assert_response :success
    assert_equal(Time.zone.today, entry.billing_date)
    assert_equal(Time.zone.today + contracts(:webauftritt).payment_period.days, entry.due_date)
    assert_equal(employees(:mark, :lucien, :pascal).sort, entry.employees.sort)
    assert_equal([work_items(:webauftritt)], entry.work_items)
    assert(test_entry.order.default_billing_address_id, entry.billing_address_id)
  end

  test 'GET preview_total' do
    params = {
      order_id: test_entry.order_id,
      employee_id: employees(:mark).id,
      work_item_id: work_items(:webauftritt).id,
      start_date: '01.12.2006',
      end_date: '31.12.2006'
    }

    xhr :get, :preview_total, params.merge(format: :js)
    preview_value = response.body[/html\('(.+) CHF'\)/, 1].to_f

    get :create, params
    assert_equal(entry.calculated_total_amount, preview_value)
  end

  test 'GET billing_addresses' do
    xhr :get, :billing_addresses, order_id: test_entry.order_id, invoice: { billing_client_id: clients(:swisstopo).id }

    assert_equal clients(:swisstopo), assigns(:billing_client)
    assert_equal billing_addresses(:swisstopo, :swisstopo_2), assigns(:billing_addresses)
  end

  private

  # Test object used in several tests.
  def test_entry
    invoices(:webauftritt_may)
  end

  def test_entry_attrs
    {
      order_id: orders(:webauftritt).id,
      employee_ids: Array(employees(:pascal).id),
      work_item_ids: Array(work_items(:webauftritt).id),
      period_from: Date.parse('01.12.2006'),
      period_to: Date.parse('15.12.2006')
    }
  end

  def edit_entry_attrs
    {
      employee_ids: Array(employees(:lucien).id),
      period_from: Date.parse('01.12.2007'),
      period_to: Date.parse('15.12.2007')
    }
  end
end
