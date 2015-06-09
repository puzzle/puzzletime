# encoding: UTF-8

require 'test_helper'

class EditContractTest < ActionDispatch::IntegrationTest
  fixtures :all
  setup :login

  test "fills the form values correctly" do
    assert_equal 'asdf1234', find_field('contract_number').value
    assert_equal '01.01.2014', find_field('contract_start_date').value
    assert_equal '30.07.2015', find_field('contract_end_date').value
    assert_equal '30', find_field('contract_payment_period').value
    assert_equal 'order asdf 1234', find_field('contract_reference').value
    assert_equal 'Reaktionszeit: 1ms', find_field('contract_sla').value

  end

  def order
    orders(:puzzletime)
  end

  def login
    login_as(:mark, edit_order_contract_path(order_id: order))
  end

end
