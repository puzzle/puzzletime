#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

# For full revenue report test see DepartmentRevenueReportTest
class ServiceRevenueReportTest < ActiveSupport::TestCase

  setup do
    travel_to Date.new(2000, 9, 5)
    Worktime.destroy_all
  end

  teardown do
    travel_back
  end

  test 'entries and values without any ordertimes and plannings' do
    r = report
    assert_equal [], r.entries
    assert_equal Hash[], r.ordertime_hours
    assert_equal Hash[], r.total_ordertime_hours_per_month
    assert_equal 0, r.total_ordertime_hours_per_entry(software)
    assert_equal 0, r.total_ordertime_hours_per_entry(system)
    assert_equal 0, r.average_ordertime_hours_per_entry(software)
    assert_equal 0, r.average_ordertime_hours_per_entry(system)
    assert_equal 0, r.total_ordertime_hours_overall
    assert_equal 0, r.average_ordertime_hours_overall
    assert_equal Hash[], r.planning_hours
    assert_equal Hash[], r.total_planning_hours_per_month
  end

  test 'entries and values' do
    accounting_posts(:hitobito_demo_app).update_attribute(:service_id, system.id)
    system.update(active: false)

    ordertime(Date.new(2000, 7, 10), :puzzletime)
    ordertime(Date.new(2000, 7, 11), :puzzletime)
    ordertime(Date.new(2000, 8, 10), :puzzletime)
    ordertime(Date.new(2000, 7, 10), :hitobito_demo_app) # inactive service

    planning(Date.new(2000, 9, 11), :hitobito_demo_app) # inactive service
    planning(Date.new(2000, 11, 10), :hitobito_demo_app) # inactive service
    planning(Date.new(2000, 11, 13), :hitobito_demo_app) # inactive service
    planning(Date.new(2000, 11, 10), :webauftritt)

    r = report
    assert_equal [software, system], r.entries.to_a
    assert_equal Hash[[software.id, Date.new(2000, 7, 1)] => 6.0,
                      [software.id, Date.new(2000, 8, 1)] => 3.0,
                      [system.id, Date.new(2000, 7, 1)] => 170.0], r.ordertime_hours
    assert_equal Hash[Date.new(2000, 7, 1) => 176.0, Date.new(2000, 8, 1) => 3.0], r.total_ordertime_hours_per_month
    assert_equal 9.0, r.total_ordertime_hours_per_entry(software)
    assert_equal 170.0, r.total_ordertime_hours_per_entry(system)
    assert_equal 4.5, r.average_ordertime_hours_per_entry(software)
    assert_equal 170.0, r.average_ordertime_hours_per_entry(system)
    assert_equal 179.0, r.total_ordertime_hours_overall
    assert_equal 89.5, r.average_ordertime_hours_overall
    assert_equal Hash[[system.id, Date.new(2000, 9, 1)] => 6.4 * 170.0,
                      [system.id, Date.new(2000, 11, 1)] => 6.4 * 170.0 * 2,
                      [software.id, Date.new(2000, 11, 1)] => 6.4 * 140.0], r.planning_hours
    assert_equal Hash[Date.new(2000, 9, 1) => 6.4 * 170.0,
                      Date.new(2000, 11, 1) => 6.4 * 170.0 * 2 + 6.4 * 140.0], r.total_planning_hours_per_month
  end

  private

  def report(report_period = period, report_params = {})
    Reports::Revenue::Service.new(report_period, report_params)
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

  def software
    services(:software)
  end

  def system
    services(:system)
  end

end
