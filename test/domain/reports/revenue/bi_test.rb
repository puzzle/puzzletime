#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class BIRevenueReportTest < ActiveSupport::TestCase
  setup do
    travel_to Date.new(2_000, 9, 5)
    Worktime.destroy_all
  end

  teardown { travel_back }

  test 'entries and values without any ordertimes and plannings' do
    r = report
    assert_equal [], r.stats
  end

  test 'entries and values' do
    Settings.clients.stubs(:company_id).returns(0) # TODO: do not use puzzle as example

    ordertime(Date.new(2_000, 1, 10), :puzzletime) # before period (ignored)
    ordertime(Date.new(2_000, 7, 10), :puzzletime)
    ordertime(Date.new(2_000, 7, 11), :puzzletime)
    ordertime(Date.new(2_000, 8, 10), :puzzletime)
    ordertime(Date.new(2_000, 7, 10), :hitobito_demo_app)
    ordertime(Date.new(2_000, 7, 10), :allgemein) # offered rate = 0
    ordertime(Date.new(2_000, 7, 10), :puzzletime, false) # work time not billable (ignored)
    ordertime(Date.new(2_000, 9, 10), :puzzletime) # in the future (ignored)

    planning(Date.new(2_000, 7, 10), :hitobito_demo_app) # in the past (ignored)
    planning(Date.new(2_000, 9, 11), :hitobito_demo_app)
    planning(Date.new(2_000, 11, 10), :hitobito_demo_app)
    planning(Date.new(2_000, 11, 13), :hitobito_demo_app)
    planning(Date.new(2_000, 11, 10), :webauftritt)
    planning(Date.new(2_000, 11, 10), :allgemein) # offered rate = 0
    planning(Date.new(2_000, 11, 14), :hitobito_demo_app, false) # provisional (ignored)
    planning(Date.new(2_000, 11, 10), :puzzletime) # accounting post not billable (ignored)
    planning(Date.new(2_000, 12, 1), :hitobito_demo_app) # after period (ignored)

    r = report
    # The test uses the same setup as DepartmentRevenueReportTest

    stats = r.stats

    assert_equal(9, stats.count)
    assert_includes(
      r.stats,
      {
        name: 'revenue_planning',
        fields: { volume: 2176.0 },
        tags: {
          time_delta: '+ 2 months', department: 'devtwo', month: '2000-11'
        }
      }
    )
    assert_includes(
      r.stats,
      {
        name: 'revenue_ordertime',
        fields: { volume: 6.0 },
        tags: {
          time_delta: '- 2 months', department: 'devone', month: '2000-07'
        }
      }
    )
  end

  private

  def report
    Reports::Revenue::BI.new
  end

  def period(
    start_date = Date.new(2_000, 7, 1), end_date = Date.new(2_000, 11, 30)
  )
    Period.new(start_date, end_date)
  end

  def ordertime(date, work_item_uuid, billable = true)
    Fabricate(
      :ordertime,
      work_date: date,
      work_item: work_items(work_item_uuid),
      employee: employees(:pascal),
      hours: 1,
      billable: billable
    )
  end

  def planning(date, work_item_uuid, definitive = true)
    Fabricate(
      :planning,
      date: date,
      work_item: work_items(work_item_uuid),
      employee: employees(:pascal),
      percent: 80,
      definitive: definitive
    )
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
