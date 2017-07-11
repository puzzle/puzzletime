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

    assert_equal I18n.l(Time.zone.today + order.contract.payment_period.days), find_field('invoice_due_date').value
    assert find_field("invoice_billing_address_id_#{order.default_billing_address_id}").checked?
  end

  test 'click on manual toggles invoice filters visibility' do
    manual_checkbox = find_field('manual_invoice')
    refute manual_checkbox.checked?

    affected_selectors = [
      "input[name='invoice[employee_ids][]']",
      "input[name='invoice[work_item_ids][]']",
      "input[name='invoice[grouping]']"
    ]
    assert affected_selectors.all? { |selector| all(selector).present? }
    manual_checkbox.click
    assert affected_selectors.none? { |selector| all(selector).present? }
    manual_checkbox.click
    assert affected_selectors.all? { |selector| all(selector).present? }
  end

  test 'sets calculated total on page load' do
    expected_total = '%.2f' % (billable_hours * rate).round(2)
    assert_match expected_total, find('#invoice_total_amount').text.delete("'")
  end

  test 'lists only employees with ordertimes on page load' do
    all(:name, 'invoice[employee_ids][]').map(&:value)
    assert_arrays_match employees(:mark, :lucien).map(&:id).map(&:to_s), all(:name, 'invoice[employee_ids][]').map(&:value)

    reload(invoice: {period_to: '8.12.2006'})
    assert_arrays_match [employees(:mark).id.to_s], all(:name, 'invoice[employee_ids][]').map(&:value)

    reload(invoice: {period_from: '12.12.2006'})
    assert_arrays_match [employees(:lucien).id.to_s], all(:name, 'invoice[employee_ids][]').map(&:value)

    reload(invoice: {period_from: '09.12.2006', period_to: '11.12.2006'})
    assert_empty all(:name, 'invoice[employee_ids][]')
  end


  test 'lists only work_items with ordertimes on page load' do
    order = Fabricate(:order)
    work_items = Fabricate.times(2, :work_item, parent: order.work_item)
    work_items.each {|w| Fabricate(:accounting_post, work_item: w) }

    from, to = Date.parse('09.12.2006'), Date.parse('10.12.2006')

    (from..to).each_with_index do |date, index|
      Fabricate(:ordertime,
                work_date: date,
                work_item: work_items[index],
                employee: employees(:pascal)
      )
    end

    reload(order: order)
    assert_arrays_match work_items.map {|w| w.id.to_s }, all(:name, 'invoice[work_item_ids][]').map(&:value)

    reload(order: order, invoice: {period_from: '11.12.2006'})
    assert_empty all(:name, 'invoice[work_item_ids][]').map(&:value)

    reload(order: order, invoice: {period_to: '08.12.2006'})
    assert_empty all(:name, 'invoice[work_item_ids][]').map(&:value)

    reload(order: order, invoice: {period_from: '10.12.2006'})
    assert_arrays_match [work_items.last.id.to_s], all(:name, 'invoice[work_item_ids][]').map(&:value)

    reload(order: order, invoice: {period_to: '09.12.2006'})
    assert_arrays_match [work_items.first.id.to_s], all(:name, 'invoice[work_item_ids][]').map(&:value)

    reload(order: order, invoice: {period_from: '09.12.2006', period_to: '10.12.2006'})
    assert_arrays_match work_items.map {|w| w.id.to_s }, all(:name, 'invoice[work_item_ids][]').map(&:value)
  end

  test 'check employee checkbox updates calculated total' do
    assert_change -> { find('#invoice_total_amount').text } do
      find_field("invoice_employee_ids_#{employees(:mark).id}").click
      sleep(0.5) # give the xhr request some time to complete
    end
  end

  test 'set from date updates employee checkboxes' do
    # check precondition
    assert has_css?("#employee_checkboxes", text: "Waber Mark")

    # set date, assert
    change_date('invoice_period_from', '09.12.2006')
    refute has_css?("#employee_checkboxes", text: "Waber Mark")

    change_date('invoice_period_from', '08.12.2006')
    assert has_css?("#employee_checkboxes", text: "Waber Mark")
  end

  test 'set to date updates employee checkboxes' do
    # check precondition
    assert has_css?("#employee_checkboxes", text: "Waber Mark")

    # set date, assert
    change_date('invoice_period_to', '07.12.2006')
    refute has_css?("#employee_checkboxes", text: "Waber Mark")

    change_date('invoice_period_to', '08.12.2006')
    assert has_css?("#employee_checkboxes", text: "Waber Mark")
  end

  test 'set to date updates work_items checkboxes' do
    # check precondition
    assert has_css?("#work_item_checkboxes", text: "STOP-WEB: Webauftritt")

    # set date, assert
    change_date('invoice_period_to', '07.12.2006')
    refute has_css?("#work_item_checkboxes", text: "STOP-WEB: Webauftritt")

    change_date('invoice_period_to', '08.12.2006')
    assert has_css?("#work_item_checkboxes", text: "STOP-WEB: Webauftritt")
  end

  test 'change of billing client changes billing addresses' do
    selectize('invoice_billing_client_id', 'Puzzle')
    assert find('#billing_addresses').has_content?('Eigerplatz')
  end

  def order
    orders(:webauftritt)
  end

  def order_employees
    Employee.where(id: order.worktimes.billable.select(:employee_id).distinct)
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

  def login(params = {})
    login_as(:mark, new_order_invoice_path(order, params))
  end

  def reload(params = {})
    order = params.delete(:order) || self.order
    visit(new_order_invoice_path(order, params))
  end

  def change_date(label, date_string)
    page.find("##{label}").click
    fill_in(label, with: date_string)
    page.find("#ui-datepicker-div .ui-datepicker-current-day a").click
    sleep(0.5) # give the xhr request some time to complete
  end

  # asserts that the checkboxes match the models by value/id and the checked state
  def assert_checkboxes(checkboxes, models, checked = models)
    assert_equal models.map { |m| m.id.to_s }.sort, checkboxes.map(&:value).sort
    models.all? do |model|
      assertion = checked.include?(model) ? :assert : :refute
      send assertion, checkboxes.find { |checkbox| checkbox.value == model.id.to_s }.checked?
    end
  end
end
