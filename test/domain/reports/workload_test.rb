require 'test_helper'

class WorkloadTest < ActiveSupport::TestCase


  test 'has correct summary entries' do
    assert_equal ["Puzzle ITC", departments(:devtwo)], report.summary.map(&:label)
  end

  test 'has entries for employees of department with worktime without employment' do
    # one entry for each employee of the department during the period
    report = report(Period.new("1.1.2006", "31.12.2006"))
    assert_equal employees(:lucien, :pascal), report.entries.map(&:employee)
  end

  test 'has entries for employees of department with employment during period' do
    employees(:half_year_maria).update(department: departments(:devtwo))
    report = report(Period.new("1.1.2006", "31.12.2006"))
    assert_includes(report.entries.map(&:employee), employees(:half_year_maria))
  end

  test 'employee must_hours' do
    employment1 = Fabricate(:employment, employee: employees(:lucien),
                           start_date: "1.9.1900", end_date: "15.9.1900")
    assert_equal 1, report.entries.count

    employment1.update(percent: 100)
    assert_equal employment1.musttime(period), report.entries.first.must_hours

    employment1.update(percent: 70)
    assert_equal employment1.musttime(period), report.entries.first.must_hours

    employment1.update(start_date: "1.1.1800")
    assert_equal employment1.musttime(period), report.entries.first.must_hours

    employment2 = Fabricate(:employment, employee: employees(:lucien), percent: 50,
                            start_date: "16.9.1900", end_date: "30.9.1900")

    expected = employment1.musttime(period) + employment2.musttime(period)
    assert_equal expected, report.entries.first.must_hours
  end

  test 'employee ordertime_hours' do
    Fabricate(:ordertime, hours: 2, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)
    Fabricate(:ordertime, hours: 3, work_item: work_items(:hitobito_demo_app),
              employee: employees(:lucien), work_date: period.end_date)

    assert_equal 5, report.entries.first.ordertime_hours
  end

  test 'employee paid_absence_hours' do
    Fabricate(:absencetime, hours: 2, employee: employees(:lucien), work_date: period.start_date)
    Fabricate(:absencetime, hours: 3, employee: employees(:lucien), work_date: period.end_date)

    assert_equal 5, report.entries.first.paid_absence_hours
  end

  test 'employee worktime_balance' do
    Fabricate(:employment, percent: 50, employee: employees(:lucien),
              start_date: period.start_date, end_date: period.end_date)

    assert_equal -80, report.entries.first.worktime_balance

    Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)
    assert_equal -77.5, report.entries.first.worktime_balance

    Fabricate(:absencetime, hours: 10.5, employee: employees(:lucien), work_date: period.end_date)
    assert_equal -67, report.entries.first.worktime_balance

    Fabricate(:ordertime, hours: 68, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)
    assert_equal 1, report.entries.first.worktime_balance
  end

  test 'employee billable_hours' do
    Fabricate(:ordertime, billable: false, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)
    assert_equal 0, report.entries.first.billable_hours

    Fabricate(:ordertime, billable: true, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)
    assert_equal 2.5, report.entries.first.billable_hours
  end

  test 'employee workload' do
    # Hours on internal Project
    Fabricate(:ordertime, hours: 5, work_item: work_items(:hitobito_demo_site),
              employee: employees(:lucien), work_date: period.start_date)

    # Billable hours on external Project
    Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)

    # Non-Billable hours on external Projek
    Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date, billable: false)

    assert_equal 50, report.entries.first.workload
  end

  test 'employee billability' do
    # Billable hours on external Project
    Fabricate(:ordertime, hours: 6, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)

    # Non-Billable hours on external Projekct
    Fabricate(:ordertime, hours: 2, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date, billable: false)

    assert_equal 75, report.entries.first.billability
  end

  test 'employee worktime_entries' do
    # Hours on Projekt A
    Fabricate(:ordertime, hours: 5, work_item: work_items(:hitobito_demo_site),
              employee: employees(:lucien), work_date: period.start_date)

    # Hours on Projekt B
    Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)
    Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date, billable: false)

    assert_equal work_items(:webauftritt, :hitobito_demo),
        report.entries.first.order_entries.map(&:work_item)
  end

  test 'summary fte' do
    # employments for selected department
    Fabricate(:employment, percent: 50, employee: employees(:pascal),
              start_date: period.start_date, end_date: period.end_date)
    Fabricate(:employment, percent: 30, employee: employees(:lucien),
              start_date: period.start_date, end_date: period.end_date)

    # employment for other department
    Fabricate(:employment, percent: 60, employee: employees(:mark),
              start_date: period.start_date, end_date: period.end_date)

    puzzle_summary, department_summary = report.summary

    assert_equal 1.4, puzzle_summary.employment_fte
    assert_equal 0.8, department_summary.employment_fte
  end

  test 'summary must_hour' do
    # Employments for selected department
    e1 = Fabricate(:employment, percent: 50, employee: employees(:pascal),
              start_date: "1.1.1900", end_date: "31.12.1900")
    e2 = Fabricate(:employment, percent: 30, employee: employees(:lucien),
              start_date: "1.1.1900", end_date: "31.12.1900")

    # Employment for other department
    e3 = Fabricate(:employment, percent: 60, employee: employees(:mark),
              start_date: "1.1.1900", end_date: "31.12.1900")

    puzzle_summary, department_summary = report.summary

    expected_for_department = e1.musttime(period) + e2.musttime(period)
    expected_for_puzzle = expected_for_department + e3.musttime(period)

    assert_equal expected_for_department, department_summary.must_hours
    assert_equal expected_for_puzzle, puzzle_summary.must_hours
  end

  test 'summary ordertime_hours' do
    # Hours on internal project
    t1 = Fabricate(:ordertime, hours: 5, work_item: work_items(:hitobito_demo_site),
              employee: employees(:lucien), work_date: period.start_date)

    # Billable hours on external project
    t2 = Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)

    # Non-Billable hours on external project
    t3 = Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date, billable: false)

    # Hours for other department
    o = Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:mark), work_date: period.start_date)

    puzzle_summary, department_summary = report.summary

    expected_for_department = [t1, t2, t3].map(&:hours).sum
    expected_for_puzzle = expected_for_department + o.hours

    assert_equal expected_for_department, department_summary.ordertime_hours
    assert_equal expected_for_puzzle, puzzle_summary.ordertime_hours
  end

  test 'summary paid_absence_hours' do
    # Absencetime for department
    Fabricate(:absencetime, hours: 2, employee: employees(:lucien), work_date: period.start_date)

    # Absencetime for other department
    Fabricate(:absencetime, hours: 3, employee: employees(:mark), work_date: period.end_date)

    puzzle_summary, department_summary = report.summary

    assert_equal 2, department_summary.paid_absence_hours
    assert_equal 5, puzzle_summary.paid_absence_hours
  end

  test 'summary worktime_balance' do
    skip 'TODO'
  end

  test 'summary external_client_hours' do
    # Hours on internal project
    i1 = Fabricate(:ordertime, hours: 5, work_item: work_items(:hitobito_demo_site),
              employee: employees(:lucien), work_date: period.start_date)

    # Billable hours on external project
    t1 = Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)

    # Non-Billable hours on external project
    t2 = Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date, billable: false)

    # Hours for other department on internal project
    i2 = Fabricate(:ordertime, hours: 5, work_item: work_items(:hitobito_demo_site),
              employee: employees(:mark), work_date: period.start_date)

    # Hours for other department on external project
    o1 = Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:mark), work_date: period.start_date)

    puzzle_summary, department_summary = report.summary

    expected_for_department = t1.hours + t2.hours
    expected_for_puzzle = expected_for_department + o1.hours

    assert_equal expected_for_department, department_summary.external_client_hours
    assert_equal expected_for_puzzle, puzzle_summary.external_client_hours
  end

  test 'summary billable_hours' do
    # Billable hours on external project
    t = Fabricate(:ordertime, hours: 2.5, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date)

    # Non-Billable hours on external project
    n1 = Fabricate(:ordertime, hours: 3.6, work_item: work_items(:webauftritt),
              employee: employees(:lucien), work_date: period.start_date, billable: false)

    # Billable hours for other department on external project
    o = Fabricate(:ordertime, hours: 4.7, work_item: work_items(:webauftritt),
              employee: employees(:mark), work_date: period.start_date)

    # Non-Billable hours for other department on external project
    n2 = Fabricate(:ordertime, hours: 5.8, work_item: work_items(:webauftritt),
              employee: employees(:mark), work_date: period.start_date, billable: false)

    puzzle_summary, department_summary = report.summary

    expected_for_department = t.hours
    expected_for_puzzle = expected_for_department + o.hours

    assert_equal expected_for_department, department_summary.billable_hours
    assert_equal expected_for_puzzle, puzzle_summary.billable_hours
  end

  test 'summary workload' do
    skip 'TODO'
  end

  test 'summary billability' do
    skip 'TODO'
  end

  test 'summary absolute_billability' do
    skip 'TODO'
  end


  private

  def report(period = period, department = department)
    @report = Reports::Workload.new(period, department)
  end

  def period
    Period.new("1.9.1900", "30.9.1900")
  end

  def department
    departments(:devtwo)
  end
end
