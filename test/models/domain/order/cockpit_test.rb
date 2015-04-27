# encoding: UTF-8
require 'test_helper'

class Order::CockpitTest < ActiveSupport::TestCase

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
    assert_equal 300, budget.hours
    assert_equal 37.5, budget.days
    assert_equal 39_000.0, budget.amount

    a1 = cockpit.rows.second
    budget = a1.cells[:budget]
    assert_equal 200, budget.hours
    assert_equal 25.0, budget.days
    assert_equal 24_000, budget.amount
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
    assert_equal 3420.0, supplied.amount

    a1 = cockpit.rows.second
    supplied = a1.cells[:supplied_services]
    assert_equal 16, supplied.hours
    assert_equal 2.0, supplied.days
    assert_equal 1920, supplied.amount
  end

  test 'not billable values are calculated if worktimes exist' do
    define_offered_fields
    define_worktimes

    total = cockpit.rows.first
    not_billable = total.cells[:not_billable]
    assert_equal 4, not_billable.hours
    assert_equal 0.5, not_billable.days
    assert_equal nil, not_billable.amount

    a1 = cockpit.rows.second
    not_billable = a1.cells[:not_billable]
    assert_equal 4, not_billable.hours
    assert_equal 0.5, not_billable.days
    assert_equal nil, not_billable.amount

    a2 = cockpit.rows.third
    not_billable = a2.cells[:not_billable]
    assert_equal 0, not_billable.hours
    assert_equal 0, not_billable.days
    assert_equal nil, not_billable.amount
  end

  test 'open budget current values are nil if nothing is offered' do
    define_worktimes

    total = cockpit.rows.first
    budget = total.cells[:open_budget_current]
    assert_equal nil, budget.hours
    assert_equal nil, budget.days
    assert_equal nil, budget.amount
  end

  test 'open budget current values are calculated if worktimes exist' do
    define_offered_fields
    define_worktimes

    total = cockpit.rows.first
    budget = total.cells[:open_budget_current]
    assert_equal 274, budget.hours
    assert_equal 34.25, budget.days
    assert_equal 35_580.0, budget.amount

    a1 = cockpit.rows.second
    budget = a1.cells[:open_budget_current]
    assert_equal 184, budget.hours
    assert_equal 23.0, budget.days
    assert_equal 22_080.0, budget.amount
  end

  test 'cost_effectiveness_forecast' do
    define_worktimes
    forecast = (22.0 / 26 * 100).round
    assert_equal forecast, cockpit.cost_effectiveness_forecast
  end

  test 'cost_effectiveness-forecast with no worktimes' do
    assert_equal '―', cockpit.cost_effectiveness_forecast
  end

  def define_offered_fields
    accounting_posts(:hitobito_demo_app).update!(offered_hours: 200, offered_rate: 120)
    accounting_posts(:hitobito_demo_site).update!(offered_hours: 100, offered_rate: 150)
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

  def order
    @order ||= orders(:hitobito_demo)
  end

  def cockpit
    @cockpit ||= Order::Cockpit.new(order)
  end

end
