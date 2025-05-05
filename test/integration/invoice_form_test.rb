# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class NewInvoiceTest < ActionDispatch::IntegrationTest
  setup :login

  test 'without params has defaults' do
    assert_equal '', find_field('invoice_period_from').value
    assert_equal '', find_field('invoice_period_to').value
    assert_not_predicate find_field('manual_invoice'), :checked?

    assert_checkboxes(all("input[name='invoice[employee_ids][]']"), order_employees)
    assert_checkboxes(all("input[name='invoice[work_item_ids][]']"), order_work_items)

    assert_equal I18n.l(Time.zone.today + order.contract.payment_period.days), find_field('invoice_due_date').value
    assert_predicate find_field("invoice_billing_address_id_#{order.default_billing_address_id}"), :checked?
  end

  test 'click on manual toggles invoice filters visibility' do
    manual_checkbox = find_field('manual_invoice')

    assert_not_predicate manual_checkbox, :checked?

    affected_selectors = [
      "input[name='invoice[employee_ids][]']",
      "input[name='invoice[work_item_ids][]']",
      "input[name='invoice[grouping]']"
    ]

    assert(affected_selectors.all? { |selector| all(selector).present? })
    manual_checkbox.click

    assert(affected_selectors.none? { |selector| all(selector).present? })
    manual_checkbox.click

    assert(affected_selectors.all? { |selector| all(selector).present? })
  end

  test 'sets calculated total on page load' do
    expected_total = delimited_number(billable_hours * rate)
    text_on_page = find('#invoice_total_amount').text

    assert_match expected_total, text_on_page
  end

  test 'sets calculated total hours on page load' do
    expected_total = "#{delimited_number(billable_hours)} h"
    text_on_page = find('#invoice_total_hours').text

    assert_match expected_total, text_on_page
  end

  test 'lists only employees with ordertimes on page load' do
    all(:name, 'invoice[employee_ids][]').map(&:value)

    assert_arrays_match employees(:mark, :lucien).map { |e| e.id.to_s },
                        all(:name, 'invoice[employee_ids][]').map(&:value)

    reload(invoice: { period_to: '8.12.2006' })

    assert_arrays_match [employees(:mark).id.to_s], all(:name, 'invoice[employee_ids][]').map(&:value)

    reload(invoice: { period_from: '12.12.2006' })

    assert_arrays_match [employees(:lucien).id.to_s], all(:name, 'invoice[employee_ids][]').map(&:value)

    reload(invoice: { period_from: '09.12.2006', period_to: '11.12.2006' })

    assert_empty all(:name, 'invoice[employee_ids][]')
  end

  test 'lists only work_items with ordertimes on page load' do
    order = Fabricate(:order)
    work_items = Fabricate.times(2, :work_item, parent: order.work_item)
    work_items.each { |w| Fabricate(:accounting_post, work_item: w) }

    from = Date.parse('09.12.2006')
    to = Date.parse('10.12.2006')

    (from..to).each_with_index do |date, index|
      Fabricate(:ordertime,
                work_date: date,
                work_item: work_items[index],
                employee: employees(:pascal))
    end

    reload(order:)

    assert_arrays_match work_items.map { |w| w.id.to_s }, all(:name, 'invoice[work_item_ids][]').map(&:value)

    reload(order:, invoice: { period_from: '11.12.2006' })

    assert_empty all(:name, 'invoice[work_item_ids][]').map(&:value)

    reload(order:, invoice: { period_to: '08.12.2006' })

    assert_empty all(:name, 'invoice[work_item_ids][]').map(&:value)

    reload(order:, invoice: { period_from: '10.12.2006' })

    assert_arrays_match [work_items.last.id.to_s], all(:name, 'invoice[work_item_ids][]').map(&:value)

    reload(order:, invoice: { period_to: '09.12.2006' })

    assert_arrays_match [work_items.first.id.to_s], all(:name, 'invoice[work_item_ids][]').map(&:value)

    reload(order:, invoice: { period_from: '09.12.2006', period_to: '10.12.2006' })

    assert_arrays_match work_items.map { |w| w.id.to_s }, all(:name, 'invoice[work_item_ids][]').map(&:value)
  end

  test 'passing work_item_ids via params sets them correctly in the invoice' do
    order = Fabricate(:order)
    work_items = Fabricate.times(3, :work_item, parent: order.work_item)
    work_items.each { |w| Fabricate(:accounting_post, work_item: w) }

    from = Date.parse('09.12.2006')
    to = Date.parse('11.12.2006')

    (from..to).each_with_index do |date, index|
      Fabricate(:ordertime,
                work_date: date,
                work_item: work_items[index],
                employee: employees(:pascal))
    end

    work_item_subset = work_items[1..]

    reload(order:, work_item_ids: work_item_subset.pluck(:id))

    checked_work_item_ids = all(:css, 'input[name="invoice[work_item_ids][]"]:checked').map { |x| x.value.to_i }

    assert_arrays_match work_item_subset.pluck(:id), checked_work_item_ids
  end

  test 'check employee checkbox updates calculated total' do
    assert_change -> { find('#invoice_total_amount').text } do
      find_field("invoice_employee_ids_#{employees(:mark).id}").click
      sleep(0.5) # give the xhr request some time to complete
    end
  end

  test 'check employee checkbox updates calculated hours' do
    assert_change -> { find('#invoice_total_hours').text } do
      find_field("invoice_employee_ids_#{employees(:mark).id}").click
      sleep(0.5) # give the xhr request some time to complete
    end
  end

  test 'set from date updates employee checkboxes' do
    # check precondition
    assert has_css?('#employee_checkboxes', text: 'Waber Mark')

    # set date, assert
    change_date('invoice_period_from', '09.12.2006')

    assert_not has_css?('#employee_checkboxes', text: 'Waber Mark')

    change_date('invoice_period_from', '08.12.2006')

    assert has_css?('#employee_checkboxes', text: 'Waber Mark')
  end

  test 'set to date updates employee checkboxes' do
    # check precondition
    assert has_css?('#employee_checkboxes', text: 'Waber Mark')

    # set date, assert
    change_date('invoice_period_to', '07.12.2006')

    assert_not has_css?('#employee_checkboxes', text: 'Waber Mark')

    change_date('invoice_period_to', '08.12.2006')

    assert has_css?('#employee_checkboxes', text: 'Waber Mark')
  end

  test 'set to date updates work_items checkboxes' do
    # check precondition
    assert has_css?('#work_item_checkboxes', text: 'STOP-WEB: Webauftritt')

    # set date, assert
    change_date('invoice_period_to', '07.12.2006')

    assert_not has_css?('#work_item_checkboxes', text: 'STOP-WEB: Webauftritt')

    change_date('invoice_period_to', '08.12.2006')

    assert has_css?('#work_item_checkboxes', text: 'STOP-WEB: Webauftritt')
  end

  test 'change of billing client changes billing addresses' do
    selectize('invoice_billing_client_id', 'Puzzle')

    assert find('#billing_addresses').has_content?('Eigerplatz')
  end

  test 'passing start / end date params or a period shortcut sets date fields' do
    reload({ start_date: '01.11.2006', end_date: '08.12.2006' })

    assert_equal '01.11.2006', find('#invoice_period_from')['value']
    assert_equal '08.12.2006', find('#invoice_period_to')['value']

    reload({ period_shortcut: '-1m' })
    period = Period.parse('-1m')

    assert_equal Period.parse_date(period.start_date), Period.parse_date(find('#invoice_period_from')['value'])
    assert_equal Period.parse_date(period.end_date), Period.parse_date(find('#invoice_period_to')['value'])
  end

  test 'setting the period shortcut disables the date fields, unsetting it enables the date fields' do
    put_period_shortcut('-1m')

    assert find('#invoice_period_from')['disabled']
    assert find('#invoice_period_to')['disabled']

    clear_period_shortcut

    assert_not find('#invoice_period_from')['disabled']
    assert_not find('#invoice_period_to')['disabled']
  end

  test 'set to period_shortcut updates employee checkboxes' do
    assert has_css?('#employee_checkboxes', text: 'Waber Mark')

    put_period_shortcut('-1m')

    assert_not has_css?('#employee_checkboxes', text: 'Waber Mark')

    clear_period_shortcut

    assert has_css?('#employee_checkboxes', text: 'Waber Mark')
  end

  test 'set to period_shortcut updates work_items checkboxes' do
    assert has_css?('#work_item_checkboxes', text: 'STOP-WEB: Webauftritt')

    put_period_shortcut('-1m')

    assert_not has_css?('#work_item_checkboxes', text: 'STOP-WEB: Webauftritt')

    clear_period_shortcut

    assert has_css?('#work_item_checkboxes', text: 'STOP-WEB: Webauftritt')
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
    login_as(:mark)
    visit new_order_invoice_path(order, params)
  end

  def reload(params = {})
    order = params.delete(:order) || self.order
    visit(new_order_invoice_path(order, params))
  end

  def change_date(label, date_string)
    page.find("##{label}").click
    fill_in(label, with: date_string)
    page.find('#ui-datepicker-div .ui-datepicker-current-day a').click
    sleep(0.5) # give the xhr request some time to complete
  end

  def put_period_shortcut(period_shortcut)
    find('#period_shortcut').click
    find("option[value=\"#{period_shortcut}\"]").select_option
    sleep(0.5)
  end

  def clear_period_shortcut
    find('#period_shortcut').click
    find("option[value='']").select_option
    sleep(0.5)
  end

  # asserts that the checkboxes match the models by value/id and the checked state
  def assert_checkboxes(checkboxes, models, checked = models)
    assert_equal models.map { |m| m.id.to_s }.sort, checkboxes.map(&:value).sort
    models.all? do |model|
      assertion = checked.include?(model) ? :assert : :refute
      send assertion, checkboxes.find { |checkbox| checkbox.value == model.id.to_s }.checked?
    end
  end

  def delimited_number(number)
    ActiveSupport::NumberHelper.number_to_rounded(
      number,
      precision: 2,
      delimiter: "'"
    )
  end
end
