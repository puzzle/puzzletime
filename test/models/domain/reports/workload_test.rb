# encoding: utf-8

require 'test_helper'

class Reports::WorkloadTest < ActiveSupport::TestCase

  ### filtering

  test 'contains entries for all employees with worktimes' do
    assert_equal employees(:lucien, :pascal), report.entries.map(&:employee)
  end

  test 'contains entries for all employees with employments' do
    Worktime.delete_all
    create_employments
    assert_equal employees(:lucien, :pascal), report.entries.map(&:employee)
  end

  test 'filter too restrictive' do
    report(period: Period.new('1.1.1000', '1.1.1900'))
    assert_equal [], report.entries
  end

  test 'filter by start date' do
    worktimes(:wt_pz_doctor).delete
    report(period: Period.new(Date.new(2006, 12, 11), nil))
    assert_equal [employees(:lucien)], report.entries.map(&:employee)
  end

  test 'filter by end date' do
    report(period: Period.new(nil, Date.new(2006, 12, 4)))
    assert_equal [employees(:pascal)], report.entries.map(&:employee)
  end

  test 'filter by period' do
    report(period: Period.new(Date.new(2006, 12, 1), Date.new(2006, 12, 4)))
    assert_equal [employees(:pascal)], report.entries.map(&:employee)
  end

  ### sorting

  test 'sort by employee' do
    report(sort: 'employee')
    assert_equal employees(:lucien, :pascal), report.entries.map(&:employee)
  end

  test 'sort by employee desc' do
    report(sort: 'employee', sort_dir: 'desc')
    assert_equal employees(:pascal, :lucien), report.entries.map(&:employee)
  end

  test 'sort by must_hours' do
    create_employments
    report(sort: "must_hours")
    assert_equal employees(:lucien, :pascal), report.entries.map(&:employee)
  end

  test 'sort by must_hours desc' do
    create_employments
    report(sort: "must_hours", sort_dir: 'desc')
    assert_equal employees(:pascal, :lucien), report.entries.map(&:employee)
  end

  test 'sort by worktime_balance' do
    report(sort: "worktime_balance")
    assert_equal employees(:lucien, :pascal), report.entries.map(&:employee)
  end

  test 'sort by worktime_balance desc' do
    report(sort: "worktime_balance", sort_dir: 'desc')
    assert_equal employees(:pascal, :lucien), report.entries.map(&:employee)
  end

  test 'sort by ordertime_hours' do
    report(sort: "ordertime_hours")
    assert_equal employees(:lucien, :pascal), report.entries.map(&:employee)
  end

  test 'sort by ordertime_hours desc' do
    report(sort: "ordertime_hours", sort_dir: 'desc')
    assert_equal employees(:pascal, :lucien), report.entries.map(&:employee)
  end

  test 'sort by workload' do
    report(sort: "workload")
    assert_equal employees(:pascal, :lucien), report.entries.map(&:employee)
  end

  test 'sort by workload desc' do
    report(sort: "workload", sort_dir: 'desc')
    assert_equal employees(:lucien, :pascal), report.entries.map(&:employee)
  end

  test 'sort by billability' do
    report(sort: "billability")
    assert_equal employees(:lucien, :pascal), report.entries.map(&:employee)
  end

  test 'sort by billability desc' do
    report(sort: "billability", sort_dir: 'desc')
    assert_equal employees(:pascal, :lucien), report.entries.map(&:employee)
  end


  ### calculating



  private

  def report(params = {})
    department = params.delete(:department) || departments(:devtwo)
    period = params.delete(:period) || Period.new('1.1.2006', '31.12.2006')
    @report ||= Reports::Workload.new(period, department, params)
  end

  def create_employments
    Employment.create!(employee: employees(:pascal), start_date: Date.parse('1.1.2006'), percent: 80)
    Employment.create!(employee: employees(:lucien), start_date: Date.parse('1.1.2006'), percent: 100)
  end

end
