# encoding: utf-8
require 'test_helper'

class NewInvoiceTest < ActionDispatch::IntegrationTest
  setup :login

  test 'without params has defaults' do
    assert_equal '', find_field('invoice_period_from').value
    assert_equal '', find_field('invoice_period_to').value
    refute find_field('manual_invoice').checked?

    assert_checkboxes(all("input[name='invoice[employee_ids][]']"), order_employees)
    assert_checkboxes(all("input[name='invoice[work_item_ids][]']"), order_work_items)

    assert_equal I18n.l(Date.today + order.contract.payment_period.days), find_field('invoice_due_date').value
    assert find_field("invoice_billing_address_id_#{order.default_billing_address_id}").checked?
  end

  test 'click on manual toggles invoice filters visibility' do
    manual_checkbox = find_field("manual_invoice")
    refute manual_checkbox.checked?

    affected_selectors = [
        "input[name='invoice[employee_ids][]']",
        "input[name='invoice[work_item_ids][]']",
        "input[name='invoice[grouping]']"
    ]
    assert affected_selectors.all? {|selector| all(selector).present? }
    manual_checkbox.click
    assert affected_selectors.none? {|selector| all(selector).present? }
    manual_checkbox.click
    assert affected_selectors.all? {|selector| all(selector).present? }
  end

  test 'sets calculated total on page load' do
    expected_total = '%.2f' % (billable_hours * rate).round(2)
    assert_match expected_total, find('#invoice_total_amount').text.delete("'")
  end

  test 'check employee checkbox updates calculated total' do
    assert_change -> { find('#invoice_total_amount').text } do
      find_field("invoice_employee_ids_#{employees(:mark).id}").click
      sleep(0.5) # give the xhr request some time to complete
    end
  end

  def order
    orders(:webauftritt)
  end

  def order_employees
    Employee.where(id: order.worktimes.billable.select(:employee_id).uniq)
  end

  def order_work_items
    order.accounting_posts.map(&:work_item)
  end

  def billable_hours
    order.worktimes.billable.sum(:hours)
  end

  def rate
    accounting_posts(:webauftritt).offered_rate
  end

  def login
    login_as(:mark, new_order_invoice_path(order))
  end

  # asserts that the checkboxes match the models by value/id and the checked state
  def assert_checkboxes(checkboxes, models, checked = models)
    assert_equal models.map {|m| m.id.to_s }.sort, checkboxes.map(&:value).sort
    models.all? do |model|
      assertion = checked.include?(model) ? :assert : :refute
      send assertion, checkboxes.find {|checkbox| checkbox.value == model.id.to_s }.checked?
    end
  end


end