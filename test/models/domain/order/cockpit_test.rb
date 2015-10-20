# encoding: UTF-8
require 'test_helper'

class Order::CockpitTest < ActiveSupport::TestCase

  setup { WorkingCondition.clear_cache }

  test 'cockpit has row for each accounting post and total' do
    assert_equal 3, cockpit.rows.size
    assert_kind_of Order::Cockpit::TotalRow, cockpit.rows.first
    assert_equal accounting_posts(:hitobito_demo_app), cockpit.rows.second.accounting_post
    assert_equal accounting_posts(:hitobito_demo_site), cockpit.rows.third.accounting_post
  end

  test 'budget values are nil if nothing is offered' do
    total = cockpit.rows.first
    budget = total.cells[:budget]
    assert_equal nil, budget.hours
    assert_equal nil, budget.days
    assert_equal nil, budget.amount

    a1 = cockpit.rows.second
    budget = a1.cells[:budget]
    assert_equal nil, budget.hours
    assert_equal nil, budget.days
    assert_equal nil, budget.amount
  end

  test 'budget values are based on offered fields' do
    define_offered_fields

    total = cockpit.rows.first
    budget = total.cells[:budget]
    assert_equal 300.2, budget.hours
    assert_equal 300.2/8, budget.days
    assert_equal 39_057.02, budget.amount

    a1 = cockpit.rows.second
    budget = a1.cells[:budget]
    assert_equal 200.1, budget.hours
    assert_equal 200.1/8, budget.days
    assert_equal 24_032.01, budget.amount
  end

  test 'supplied_services values are zero if no worktimes exist' do
    define_offered_fields

    total = cockpit.rows.first
    supplied = total.cells[:supplied_services]
    assert_equal 0, supplied.hours
    assert_equal 0, supplied.days
    assert_equal 0, supplied.amount

    a1 = cockpit.rows.second
    supplied = a1.cells[:supplied_services]
    assert_equal 0, supplied.hours
    assert_equal 0, supplied.days
    assert_equal 0, supplied.amount
  end

  test 'supplied_services values are calculated if worktimes exist' do
    define_offered_fields
    define_worktimes

    total = cockpit.rows.first
    supplied = total.cells[:supplied_services]
    assert_equal 26, supplied.hours
    assert_equal 3.25, supplied.days
    assert_equal 3422.6, supplied.amount

    a1 = cockpit.rows.second
    supplied = a1.cells[:supplied_services]
    assert_equal 16, supplied.hours
    assert_equal 2.0, supplied.days
    assert_equal 1921.6, supplied.amount
  end

  test 'not billable values are calculated if worktimes exist' do
    define_offered_fields
    define_worktimes

    total = cockpit.rows.first
    not_billable = total.cells[:not_billable]
    assert_equal 4, not_billable.hours
    assert_equal 0.5, not_billable.days
    assert_equal 480.4, not_billable.amount

    a1 = cockpit.rows.second
    not_billable = a1.cells[:not_billable]
    assert_equal 4, not_billable.hours
    assert_equal 0.5, not_billable.days
    assert_equal 480.4, not_billable.amount

    a2 = cockpit.rows.third
    not_billable = a2.cells[:not_billable]
    assert_equal 0, not_billable.hours
    assert_equal 0, not_billable.days
    assert_equal 0, not_billable.amount
  end

  test 'open budget current values are nil if nothing is offered' do
    define_worktimes

    total = cockpit.rows.first
    budget = total.cells[:open_services]
    assert_equal -26, budget.hours
    assert_equal -3.25, budget.days
    assert_equal -4420, budget.amount
  end

  test 'open budget current values are calculated if worktimes exist' do
    define_offered_fields
    define_worktimes

    total = cockpit.rows.first
    budget = total.cells[:open_services]
    assert_equal 274.2, budget.hours.to_f
    assert_equal 274.2/8, budget.days.to_f
    assert_equal 35_634.42, budget.amount.round(2)

    a1 = cockpit.rows.second
    budget = a1.cells[:open_services]
    assert_equal 184.1, budget.hours
    assert_equal 184.1/8, budget.days
    assert_equal 22_110.41, budget.amount.round(2)
  end

  test 'cost_effectiveness_forecast' do
    define_worktimes
    forecast = (22.0 / 26 * 100).round
    assert_equal forecast, cockpit.cost_effectiveness_forecast
  end

  test 'cost_effectiveness-forecast with no worktimes is blank' do
    assert_equal '―', cockpit.cost_effectiveness_forecast
  end

  test 'cost_effectiveness_current' do
    define_worktimes
    create_invoice

    forecast = (12.0 / 26 * 100).round
    assert_equal forecast, cockpit.cost_effectiveness_current
  end

  test 'cost_effectiveness_current with no worktimes is blank' do
    assert_equal '―', cockpit.cost_effectiveness_current
  end

  test 'budget billed without invoices is zero' do
    assert_equal 0.0, cockpit.budget_billed
  end

  test 'budget billed is total from invoices' do
    define_worktimes
    create_invoice

    assert_equal 2_040.0, cockpit.budget_billed
  end

  test 'budget open without invoices without offering is zero' do
    assert_equal 0.0, cockpit.budget_open
  end

  test 'budget open without invoices without offering is budget' do
    define_offered_fields

    assert_equal 39_057.02, cockpit.budget_open
  end

  test 'budget open with invoices without offered fields is negative' do
    define_worktimes
    create_invoice

    assert_equal -2_040.0, cockpit.budget_open
  end

  test 'budget open with invoices is difference to offered fields' do
    define_offered_fields
    define_worktimes
    create_invoice

    assert_equal 39_057.02 - 1_441.2, cockpit.budget_open
  end

  test 'average rate without invoice is nil' do
    assert_equal nil, cockpit.average_rate
  end

  test 'average rate is invoice total / hours at last period_to' do
    define_offered_fields
    define_worktimes
    create_invoice(period_to: Date.today - 1)

    assert_equal 26.69, cockpit.average_rate.round(2)
  end


  def define_offered_fields
    accounting_posts(:hitobito_demo_app).update!(offered_hours: 200.1, offered_rate: 120.1)
    accounting_posts(:hitobito_demo_site).update!(offered_hours: 100.1, offered_rate: 150.1)
  end

  def define_worktimes
    Ordertime.create!(work_item: work_items(:hitobito_demo_app),
                      employee: employees(:pascal),
                      work_date: Date.today,
                      report_type: HoursDayType::INSTANCE,
                      hours: 8)
    Ordertime.create!(work_item: work_items(:hitobito_demo_app),
                      employee: employees(:pascal),
                      work_date: Date.today - 1,
                      report_type: HoursDayType::INSTANCE,
                      hours: 4)
    Ordertime.create!(work_item: work_items(:hitobito_demo_app),
                      employee: employees(:pascal),
                      work_date: Date.today - 1,
                      report_type: HoursDayType::INSTANCE,
                      billable: false,
                      hours: 4)
    Ordertime.create!(work_item: work_items(:hitobito_demo_site),
                      employee: employees(:pascal),
                      work_date: Date.today - 2,
                      report_type: HoursDayType::INSTANCE,
                      hours: 10)
  end

  def create_invoice(attrs = {})
    Invoicing.instance = nil
    Fabricate(:contract, order: order) unless order.contract
    Fabricate(:invoice, {
              order: order,
              work_items: [work_items(:hitobito_demo_app)],
              employees: [employees(:pascal)],
              period_to: Date.today.at_end_of_month
              }.merge(attrs))
  end

  def order
    @order ||= orders(:hitobito_demo)
  end

  def cockpit
    @cockpit ||= Order::Cockpit.new(order)
  end

end
