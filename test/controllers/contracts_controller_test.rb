# encoding: UTF-8

require 'test_helper'

class ContractsControllerTest < ActionController::TestCase

  setup :login

  def test_edit
    get :edit, order_id: test_entry.order
    assert_response :success
    assert_template 'edit'
    assert_equal test_entry, entry
  end

  def test_update
    patch :update, order_id: test_entry.order, contract: test_entry_attrs
    assert_redirected_to edit_order_contract_path(order_id: test_entry.order)
    assert entry.persisted?
    test_entry_attrs_except_dates.each do |attr_name, attr_value|
      assert_equal attr_value, entry.send(attr_name)
    end
    assert_equal test_entry_start_date, entry.start_date
    assert_equal test_entry_end_date, entry.end_date
  end

  private

  # Test object used in several tests.
  def test_entry
    @test_entry ||= contracts(:puzzletime)
  end

  def test_entry_attrs
    {
        number: "asdf123456",
        start_date: "2014-01-02",
        end_date: "2015-07-29",
        payment_period: 3,
        reference: "order asdf 123456",
        sla: "Reaktionszeit: 1.5ms"
    }
  end

  def test_entry_attrs_except_dates
    test_entry_attrs.except(:start_date, :end_date)
  end

  def test_entry_start_date
    Date.parse(test_entry_attrs[:start_date])
  end

  def test_entry_end_date
    Date.parse(test_entry_attrs[:end_date])
  end

  # The entry as set by the controller.
  def entry
    @controller.send(:entry)
  end


end
