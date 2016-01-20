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
    assert_equal [], report.entries
  end

  test 'filter by kind' do
    report(kind_id: order_kinds(:projekt).id)
    assert_equal [orders(:webauftritt)], report.entries.collect(&:order)
  end

  test 'filter by responsible and department' do
    report(responsible_id: employees(:lucien).id, department_id: departments(:devone).id)
    assert_equal [orders(:puzzletime)], report.entries.collect(&:order)
  end

  test 'filter too restrictive' do
    report(kind_id: order_kinds(:mandat).id,
           department_id: departments(:sys).id,
           status_id: order_statuses(:bearbeitung).id)
    assert_equal [], report.entries
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

  # TODO


  ### pagination

  # TODO

  ### csv

  # TODO

  private

  def report(params = {})
    period = params.delete(:period) || Period.new(nil, nil)
    @report ||= Order::Report.new(period, params)
  end

end
