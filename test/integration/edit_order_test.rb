# encoding: utf-8

require 'test_helper'

class EditOrderTest < ActionDispatch::IntegrationTest

  setup :login

  test 'create order contacts fields' do
    assert has_no_field?("order_order_contacts_attributes_0_contact_id")
    assert_no_selector("a[data-object-class='order-contact'].remove_nested_fields_link")

    find("a[data-object-class='order_contact'].add_nested_fields_link").click
    assert find_field("order_order_contacts_attributes_0_contact_id", visible: false)[:class].include?('selectized')
    assert_selector("a[data-object-class='order_contact'].remove_nested_fields_link", count: 1)

    find("a[data-object-class='order_contact'].add_nested_fields_link").click
    assert find_field("order_order_contacts_attributes_1_contact_id", visible: false)[:class].include?('selectized')
    assert_selector("a[data-object-class='order_contact'].remove_nested_fields_link", count: 2)
  end

  def login
    login_as(:mark, edit_order_path(orders(:puzzletime)))
  end

end