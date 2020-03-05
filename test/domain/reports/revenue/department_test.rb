#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class DepartmentRevenueReportTest < ActiveSupport::TestCase
  setup do
    travel_to Date.new(2000, 9, 5)
    Worktime.destroy_all
  end

  teardown do
    travel_back
  end

  test '#past_months? and #future_months?' do
    r = report(period)
    assert r.past_months?
    assert r.future_months?

    r = report(period(Date.new(1999, 1, 1), Date.new(1999, 2, 1)))
    assert r.past_months?
    assert !r.future_months?

    r = report(period(Date.new(1999, 12, 31), Date.new(2000, 5, 1)))
    assert r.past_months?
    assert !r.future_months?

    r = report(period(Date.new(2000, 9, 15), Date.new(2000, 9, 20)))
    assert !r.past_months?
    assert r.future_months?

    r = report(period(Date.new(2000, 12, 1), Date.new(2001, 1, 1)))
    assert !r.past_months?
    assert r.future_months?

    r = report(period(Date.new(2010, 1, 1), Date.new(2010, 2, 1)))
    assert !r.past_months?
    assert r.future_months?
  end

  test '#step_past_months' do
    count = 0
    r = report(period)
    r.step_past_months do |_date|
      count += 1
    end
    assert_equal 2, count

    count = 0
    r = report(period(Date.new(1999, 12, 31), Date.new(2000, 5, 1)))
    r.step_past_months do |_date|
      count += 1
    end
    assert_equal 6, count

    count = 0
    r = report(period(Date.new(2000, 9, 15), Date.new(2001, 1, 1)))
    r.step_past_months do |_date|
      count += 1
    end
    assert_equal 0, count
  end

  test '#step_future_months' do
    count = 0
    r = report(period)
    r.step_future_months do |_date|
      count += 1
    end
    assert_equal 3, count

    count = 0
    r = report(period(Date.new(1999, 12, 31), Date.new(2000, 5, 1)))
    r.step_future_months do |_date|
      count += 1
    end
    assert_equal 0, count

    count = 0
    r = report(period(Date.new(2000, 9, 15), Date.new(2001, 1, 1)))
    r.step_future_months do |_date|
      count += 1
    end
    assert_equal 5, count
  end

  test 'entries and values without any ordertimes and plannings' do
    r = report
    assert_equal [], r.entries
    assert_equal Hash[], r.ordertime_hours
    assert_equal Hash[], r.total_ordertime_hours_per_month
    assert_equal 0, r.total_ordertime_hours_per_entry(devone)
    assert_equal 0, r.total_ordertime_hours_per_entry(devtwo)
    assert_equal 0, r.total_ordertime_hours_per_entry(sys)
    assert_equal 0, r.average_ordertime_hours_per_entry(devone)
    assert_equal 0, r.average_ordertime_hours_per_entry(devtwo)
    assert_equal 0, r.average_ordertime_hours_per_entry(sys)
    assert_equal 0, r.total_ordertime_hours_overall
    assert_equal 0, r.average_ordertime_hours_overall
    assert_equal Hash[], r.planning_hours
    assert_equal Hash[], r.total_planning_hours_per_month
  end

  test 'entries and values' do
    Settings.clients.stubs(:company_id).returns(0) #TODO: do not use puzzle as example

    ordertime(Date.new(2000, 1, 10), :puzzletime) # before period (ignored)
    ordertime(Date.new(2000, 7, 10), :puzzletime)
    ordertime(Date.new(2000, 7, 11), :puzzletime)
    ordertime(Date.new(2000, 8, 10), :puzzletime)
    ordertime(Date.new(2000, 7, 10), :hitobito_demo_app)
    ordertime(Date.new(2000, 7, 10), :allgemein) # offered rate = 0
    ordertime(Date.new(2000, 7, 10), :puzzletime, false) # work time not billable (ignored)
    ordertime(Date.new(2000, 9, 10), :puzzletime) # in the future (ignored)

    planning(Date.new(2000, 7, 10), :hitobito_demo_app) # in the past (ignored)
    planning(Date.new(2000, 9, 11), :hitobito_demo_app)
    planning(Date.new(2000, 11, 10), :hitobito_demo_app)
    planning(Date.new(2000, 11, 13), :hitobito_demo_app)
    planning(Date.new(2000, 11, 10), :webauftritt)
    planning(Date.new(2000, 11, 10), :allgemein) # offered rate = 0
    planning(Date.new(2000, 11, 14), :hitobito_demo_app, false) # provisional (ignored)
    planning(Date.new(2000, 11, 10), :puzzletime) # accounting post not billable (ignored)
    planning(Date.new(2000, 12, 1), :hitobito_demo_app) # after period (ignored)

    r = report
    assert_equal [devone, devtwo, sys], r.entries
    assert_equal Hash[[devone.id, Date.new(2000, 7, 1)] => 6.0,
                      [devone.id, Date.new(2000, 8, 1)] => 3.0,
                      [devtwo.id, Date.new(2000, 7, 1)] => 170.0,
                      [sys.id, Date.new(2000, 7, 1)] => 0.0], r.ordertime_hours
    assert_equal Hash[Date.new(2000, 7, 1) => 176.0, Date.new(2000, 8, 1) => 3.0], r.total_ordertime_hours_per_month
    assert_equal 9.0, r.total_ordertime_hours_per_entry(devone)
    assert_equal 170.0, r.total_ordertime_hours_per_entry(devtwo)
    assert_equal 0.0, r.total_ordertime_hours_per_entry(sys)
    assert_equal 4.5, r.average_ordertime_hours_per_entry(devone)
    assert_equal 170.0, r.average_ordertime_hours_per_entry(devtwo)
    assert_equal 0.0, r.average_ordertime_hours_per_entry(sys)
    assert_equal 179.0, r.total_ordertime_hours_overall
    assert_equal 89.5, r.average_ordertime_hours_overall
    assert_equal Hash[[devtwo.id, Date.new(2000, 9, 1)] => 6.4 * 170.0,
                      [devtwo.id, Date.new(2000, 11, 1)] => 6.4 * 170.0 * 2,
                      [devone.id, Date.new(2000, 11, 1)] => 6.4 * 140.0,
                      [sys.id, Date.new(2000, 11, 1)] => 0.0], r.planning_hours
    assert_equal Hash[Date.new(2000, 9, 1) => 6.4 * 170.0,
                      Date.new(2000, 11, 1) => 6.4 * 170.0 * 2 + 6.4 * 140.0], r.total_planning_hours_per_month
  end

  test 'entries and values with sort by past month' do
    Settings.clients.stubs(:company_id).returns(0) #TODO: do not use puzzle as example

    # same as above
    ordertime(Date.new(2000, 1, 10), :puzzletime) # before period (ignored)
    ordertime(Date.new(2000, 7, 10), :puzzletime)
    ordertime(Date.new(2000, 7, 11), :puzzletime)
    ordertime(Date.new(2000, 8, 10), :puzzletime)
    ordertime(Date.new(2000, 7, 10), :hitobito_demo_app)
    ordertime(Date.new(2000, 7, 10), :allgemein) # offered rate = 0
    ordertime(Date.new(2000, 7, 10), :puzzletime, false) # work time not billable (ignored)
    ordertime(Date.new(2000, 9, 10), :puzzletime) # in the future (ignored)

    planning(Date.new(2000, 7, 10), :hitobito_demo_app) # in the past (ignored)
    planning(Date.new(2000, 9, 11), :hitobito_demo_app)
    planning(Date.new(2000, 11, 10), :hitobito_demo_app)
    planning(Date.new(2000, 11, 13), :hitobito_demo_app)
    planning(Date.new(2000, 11, 10), :webauftritt)
    planning(Date.new(2000, 11, 10), :allgemein) # offered rate = 0
    planning(Date.new(2000, 11, 14), :hitobito_demo_app, false) # provisional (ignored)
    planning(Date.new(2000, 11, 10), :puzzletime) # accounting post not billable (ignored)
    planning(Date.new(2000, 12, 1), :hitobito_demo_app) # after period (ignored)

    r = report(period, sort: '2000-07-01', sort_dir: 'desc')
    assert_equal [devtwo, devone, sys], r.entries
    assert_equal Hash[[devone.id, Date.new(2000, 7, 1)] => 6.0,
                      [devone.id, Date.new(2000, 8, 1)] => 3.0,
                      [devtwo.id, Date.new(2000, 7, 1)] => 170.0,
                      [sys.id, Date.new(2000, 7, 1)] => 0.0], r.ordertime_hours
    assert_equal Hash[Date.new(2000, 7, 1) => 176.0, Date.new(2000, 8, 1) => 3.0], r.total_ordertime_hours_per_month
  end

  test 'entries and values from configured company are ignored' do
    ordertime(Date.new(2000, 1, 10), :puzzletime) # before period (ignored)
    ordertime(Date.new(2000, 7, 10), :puzzletime)
    ordertime(Date.new(2000, 7, 11), :puzzletime)
    ordertime(Date.new(2000, 8, 10), :puzzletime)
    ordertime(Date.new(2000, 7, 10), :hitobito_demo_app)
    ordertime(Date.new(2000, 7, 10), :allgemein) # offered rate = 0
    ordertime(Date.new(2000, 7, 10), :puzzletime, false) # work time not billable (ignored)
    ordertime(Date.new(2000, 9, 10), :puzzletime) # in the future (ignored)

    planning(Date.new(2000, 7, 10), :hitobito_demo_app) # in the past (ignored)
    planning(Date.new(2000, 9, 11), :hitobito_demo_app)
    planning(Date.new(2000, 11, 10), :hitobito_demo_app)
    planning(Date.new(2000, 11, 13), :hitobito_demo_app)
    planning(Date.new(2000, 11, 10), :webauftritt)
    planning(Date.new(2000, 11, 10), :allgemein) # offered rate = 0
    planning(Date.new(2000, 11, 14), :hitobito_demo_app, false) # provisional (ignored)
    planning(Date.new(2000, 11, 10), :puzzletime) # accounting post not billable (ignored)
    planning(Date.new(2000, 12, 1), :hitobito_demo_app) # after period (ignored)

    r = report
    assert_equal [devone], r.entries
    assert_equal Hash[], r.ordertime_hours
    assert_equal Hash[], r.total_ordertime_hours_per_month
    assert_equal 0, r.total_ordertime_hours_per_entry(devone)
    assert_equal 0, r.total_ordertime_hours_per_entry(devtwo)
    assert_equal 0, r.total_ordertime_hours_per_entry(sys)
    assert_equal 0, r.average_ordertime_hours_per_entry(devone)
    assert_equal 0, r.average_ordertime_hours_per_entry(devtwo)
    assert_equal 0, r.average_ordertime_hours_per_entry(sys)
    assert_equal 0, r.total_ordertime_hours_overall
    assert_equal 0, r.average_ordertime_hours_overall
    assert_equal Hash[[devone.id, Date.new(2000, 11, 1)] => 6.4 * 140.0], r.planning_hours
    assert_equal Hash[Date.new(2000, 11, 1) => 6.4 * 140.0], r.total_planning_hours_per_month
  end

  private

  def report(report_period = period, report_params = {})
    Reports::Revenue::Department.new(report_period, report_params)
  end

  def period(start_date = Date.new(2000, 7, 1), end_date = Date.new(2000, 11, 30))
    Period.new(start_date, end_date)
  end

  def ordertime(date, work_item_uuid, billable = true)
    Fabricate(:ordertime,
              work_date: date,
              work_item: work_items(work_item_uuid),
              employee: employees(:pascal),
              hours: 1,
              billable: billable)
  end

  def planning(date, work_item_uuid, definitive = true)
    Fabricate(:planning,
              date: date,
              work_item: work_items(work_item_uuid),
              employee: employees(:pascal),
              percent: 80,
              definitive: definitive)
  end

  def devone
    departments(:devone)
  end

  def devtwo
    departments(:devtwo)
  end

  def sys
    departments(:sys)
  end
end
