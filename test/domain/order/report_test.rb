#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Order::ReportTest < ActiveSupport::TestCase
  ### filtering

  test 'contains all orders with worktimes without filters' do
    assert_equal 3, report.entries.size
  end

  test 'filter by status' do
    report(status_id: order_statuses(:abgeschlossen))

    assert_equal [orders(:allgemein)], report.entries.collect(&:order)
  end

  test 'filter by responsible' do
    report(responsible_id: employees(:long_time_john).id)

    assert_equal [orders(:webauftritt)], report.entries.collect(&:order)
  end

  test 'filter by department' do
    report(department_id: departments(:devtwo).id)

    assert_empty report.entries
  end

  test 'filter by kind' do
    report(kind_id: order_kinds(:projekt).id)

    assert_equal [orders(:webauftritt)], report.entries.collect(&:order)
  end

  test 'filter by low risk value' do
    report(major_risk_value: 'low')

    assert_empty report.entries.collect(&:order)
  end

  test 'filter by risk value' do
    report(major_risk_value: 'medium')

    assert_equal [orders(:puzzletime)], report.entries.collect(&:order)
  end

  test 'filter by chance value' do
    report(major_chance_value: 'high')

    assert_equal [orders(:puzzletime)], report.entries.collect(&:order)
  end

  test 'filter by responsible and department' do
    report(responsible_id: employees(:lucien).id, department_id: departments(:devone).id)

    assert_equal [orders(:puzzletime)], report.entries.collect(&:order)
  end

  test 'filter too restrictive' do
    report(kind_id: order_kinds(:mandat).id,
           department_id: departments(:sys).id,
           status_id: order_statuses(:bearbeitung).id)

    assert_empty report.entries
  end

  test 'filter by client' do
    report(client_work_item_id: work_items(:puzzle).id)

    assert_equal orders(:allgemein, :puzzletime), report.entries.collect(&:order)
  end

  test 'filter by category' do
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal))
    report(client_work_item_id: work_items(:puzzle).id,
           category_work_item_id: work_items(:hitobito).id)

    assert_equal [orders(:hitobito_demo)], report.entries.collect(&:order)
  end

  test 'filter by start date' do
    report(period: Period.new(Date.new(2006, 12, 11), nil))

    assert_equal orders(:puzzletime, :webauftritt), report.entries.collect(&:order)
  end

  test 'filter by end date' do
    report(period: Period.new(nil, Date.new(2006, 12, 1)))

    assert_equal [orders(:allgemein)], report.entries.collect(&:order)
  end

  test 'filter by period' do
    report(period: Period.new(Date.new(2006, 12, 4), Date.new(2006, 12, 6)))

    assert_equal orders(:allgemein, :webauftritt), report.entries.collect(&:order)
  end

  test 'filter by target red' do
    report(target: 'red')

    assert_equal [orders(:allgemein)], report.entries.collect(&:order)
  end

  test 'filter by target red and orange' do
    report(target: 'red_orange')

    assert_equal orders(:allgemein, :puzzletime), report.entries.collect(&:order)
  end

  test 'filter by closed' do
    report(closed: true)

    assert_equal [orders(:allgemein)], report.entries.collect(&:order)
  end

  ### sorting

  test 'sort by client' do
    report(sort: 'client', sort_dir: 'desc')

    assert_equal orders(:webauftritt, :puzzletime, :allgemein), report.entries.collect(&:order)
  end

  test 'sort by target time' do
    report(sort: "target_scope_#{target_scopes(:time).id}")

    assert_equal orders(:allgemein, :puzzletime, :webauftritt), report.entries.collect(&:order)
  end

  test 'sort by target cost' do
    report(sort: "target_scope_#{target_scopes(:cost).id}", sort_dir: 'desc')

    assert_equal orders(:allgemein, :webauftritt, :puzzletime), report.entries.collect(&:order)
  end

  test 'sort by offered_amount' do
    report(sort: 'offered_amount')

    assert_equal orders(:webauftritt, :puzzletime, :allgemein), report.entries.collect(&:order)
  end

  ### calculating

  test 'it counts orders' do
    assert_equal 'Total (3)', report().total.to_s
  end

  test 'it counts filtered orders' do
    assert_equal 'Total (1)', report(closed: true).total.to_s
  end

  test '#offered_amount is sum of all accounting posts' do
    order = orders(:hitobito_demo)
    accounting_posts(:hitobito_demo_app).update!(offered_total: 10000)
    post = AccountingPost.create!(work_item_attributes:
                                    { name: 'Maintenance',
                                      shortname: 'MNT',
                                      parent_id: order.work_item_id },
                                  offered_rate: 120,
                                  offered_total: 5000,
                                  portfolio_item: portfolio_items(:web),
                                  service: services(:software))
    Fabricate(:ordertime, work_item_id: post.work_item_id, employee: employees(:pascal))
    entry = report.entries.find { |e| e.order == order }

    assert_equal 15_000, entry.offered_amount
    assert_equal 155_300, report.total.offered_amount
  end

  test '#offered_rate is based on hours' do
    order = orders(:hitobito_demo)
    accounting_posts(:hitobito_demo_app).update!(offered_total: 10000, offered_hours: 100, offered_rate: 100)
    accounting_posts(:hitobito_demo_site).update!(offered_total: 10000, offered_hours: 50, offered_rate: 200)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal))
    entry = report.entries.find { |e| e.order == order }

    assert_in_delta 133.33, entry.offered_rate, 0.1
    assert_in_delta 128.24, report.total.offered_rate, 0.1
  end

  test '#offered_rate is based on rate if no hours given' do
    order = orders(:hitobito_demo)
    AccountingPost.update_all(offered_hours: nil, offered_total: nil)
    accounting_posts(:hitobito_demo_app).update!(offered_rate: 100)
    accounting_posts(:hitobito_demo_site).update!(offered_rate: 200)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal))
    entry = report.entries.find { |e| e.order == order }

    assert_in_delta 150, entry.offered_rate, 0.1
    # total offered rate bases on avg order rate, not avg accounting post rate
    assert_in_delta 73.25, report.total.offered_rate, 0.1
  end

  test '#offered_rate is based on rate if only total given' do
    order = orders(:hitobito_demo)
    accounting_posts(:hitobito_demo_app).update!(offered_total: 10000, offered_rate: 100)
    accounting_posts(:hitobito_demo_site).update!(offered_total: 5000, offered_rate: 200)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal))
    entry = report.entries.find { |e| e.order == order }

    assert_in_delta 120, entry.offered_rate, 0.1
  end

  test '#offered_rate is based on hours even if some are missing' do
    order = orders(:hitobito_demo)
    accounting_posts(:hitobito_demo_app).update!(offered_hours: 100, offered_rate: 100)
    accounting_posts(:hitobito_demo_site).update!(offered_rate: 200)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal))
    entry = report.entries.find { |e| e.order == order }

    assert_in_delta 100, entry.offered_rate, 0.1
  end

  test '#offered_rate is based on hours even if only total is given' do
    order = orders(:hitobito_demo)
    accounting_posts(:hitobito_demo_app).update!(offered_hours: 100, offered_rate: 100)
    accounting_posts(:hitobito_demo_site).update!(offered_total: 10000, offered_rate: 200)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal))
    entry = report.entries.find { |e| e.order == order }

    assert_in_delta 133.33, entry.offered_rate, 0.1
  end

  test '#offered_hours is based on hours' do
    order = orders(:hitobito_demo)
    accounting_posts(:hitobito_demo_app).update!(offered_hours: 100)
    post = AccountingPost.create!(work_item_attributes:
                                                  { name: 'Maintenance',
                                                    shortname: 'MNT',
                                                    parent_id: order.work_item_id },
                                  offered_rate: 120,
                                  offered_hours: 200,
                                  portfolio_item: portfolio_items(:web),
                                  service: services(:software))
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal))
    entry = report.entries.find { |e| e.order == order }

    assert_equal 300, entry.offered_hours
    assert_equal 1400, report.total.offered_hours
  end

  test '#supplied and billed amount/hours is based on rate and worktime hours' do
    order = orders(:hitobito_demo)
    accounting_posts(:hitobito_demo_app).update!(offered_rate: 200)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 2)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 8)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_site), employee: employees(:pascal), hours: 5, billable: false)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_site), employee: employees(:pascal), hours: 5, billable: false, work_date: 2.years.ago)
    entry = report(period: Period.new(1.year.ago, nil)).entries.find { |e| e.order == order }

    assert_equal 2850, entry.supplied_amount
    assert_equal 2000, entry.billable_amount
    assert_equal 15, entry.supplied_hours
    assert_equal 10, entry.billable_hours
    assert_equal 67, entry.billability
    assert_in_delta 133.333, entry.average_rate, 0.001
  end

  test '#total values are the sums' do
    order = orders(:hitobito_demo)
    accounting_posts(:hitobito_demo_app).update!(offered_rate: 200)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 2)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 8)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_site), employee: employees(:pascal), hours: 5, billable: false)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_site), employee: employees(:pascal), hours: 5, billable: false, work_date: 2.years.ago)
    total = report(period: Period.new(1.year.ago, nil)).total

    assert_equal 2850, total.supplied_amount
    assert_equal 2000, total.billable_amount
    assert_equal 15, total.supplied_hours
    assert_equal 10, total.billable_hours
    assert_equal 67, total.billability
    assert_in_delta 133.333, total.average_rate, 0.001
  end

  test 'billed values without invoices are nil' do
    order = orders(:hitobito_demo)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 2)
    entry = report.entries.find { |e| e.order == order }

    assert_equal 0, entry.billed_amount
    assert_equal 0, entry.billed_hours
    assert_equal 0, entry.billed_rate
  end

  test 'billed values with invoices' do
    order = orders(:hitobito_demo)
    Fabricate(:contract, order:)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 10, work_date: 1.month.ago)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 2, work_date: 1.month.ago)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 2, work_date: 1.month.ago, billable: false)
    Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal), hours: 20, work_date: 2.years.ago)
    i1 = Fabricate(:invoice, order:, work_items: work_items(:hitobito_demo_app, :hitobito_demo_site), employees: [employees(:pascal)])
    i2 = Fabricate(:invoice, order:, work_items: [work_items(:hitobito_demo_app)], employees: [employees(:pascal)], billing_date: 2.years.ago, period_from: 2.years.ago.at_beginning_of_month, period_to: 2.years.ago.at_end_of_month)

    assert_equal 12 * 170, i1.total_amount
    assert_equal 20 * 170, i2.total_amount
    entry = report(period: Period.new(1.year.ago, nil)).entries.find { |e| e.order == order }

    assert_equal 12 * 170, entry.billed_amount.to_i
    assert_equal 12, entry.billed_hours
    assert_equal 170, entry.billed_rate

    assert_equal 12 * 170, report.total.billed_amount
    assert_equal 12, report.total.billed_hours
    assert_equal 170, report.total.billed_rate
  end

  test 'csv includes target scopes' do
    csv = Order::Report::Csv.new(report).generate.lines.to_a

    assert_match /Termin,Kosten,Qualität$/, csv.first
    assert_match /red,green,green$/, csv.second
  end

  private

  def report(params = {})
    period = params.delete(:period) || Period.new(nil, nil)
    @report ||= Order::Report.new(period, params)
  end
end
