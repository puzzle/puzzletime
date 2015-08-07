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

  test 'GET new without params sets defaults' do
    get :new, order_id: test_entry.order_id
    assert_response :success
    assert_equal(Date.today, entry.billing_date)
    assert_equal(Date.today + contracts(:webauftritt).payment_period.days, entry.due_date)
    assert_equal([employees(:pascal), employees(:mark), employees(:lucien)].sort, entry.employees.sort)
    assert_equal([work_items(:webauftritt)], entry.work_items)
    assert(test_entry.order.client.default_billing_address, entry.billing_address)
  end

  test 'GET preview_total' do
    params = {
        order_id: test_entry.order_id,
                employee_id: employees(:mark).id,
                work_item_id: work_items(:webauftritt).id,
                start_date: start_date = '01.12.2006',
                end_date: end_date = '31.12.2006'
    }

    get :preview_total, params
    preview_value = response.body

    get :create, params
    assert_equal(entry.calculated_total_amount.to_s, preview_value.chomp)
  end

  private

  # Test object used in several tests.
  def test_entry
    invoices(:webauftritt_may)
  end
end
