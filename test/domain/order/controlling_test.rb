#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class Order::ControllingTest < ActiveSupport::TestCase

  test '#offered_hours returs summed offered hours of all accounting posts' do
    Fabricate(:accounting_post, work_item: order.work_item,
                                offered_hours: 10_000)
    Fabricate(:accounting_post, work_item: Fabricate(:work_item, parent: order.work_item),
                                offered_hours: 20_000)

    assert_equal 30_000, controlling.offered_hours
  end

  test '#hours_per_week returns billable, unbillable & definitive/provisional planned hours' do
    Fabricate(:accounting_post, work_item: order.work_item, offered_hours: 10_000)
    create_time(Date.new(2000, 1, 3), 1, false)
    create_time(Date.new(2000, 1, 4), 2, false)
    create_time(Date.new(2000, 1, 3), 3, true)
    create_time(Date.new(2000, 1, 4), 4, true)
    create_time(Date.new(2000, 1, 3) + 1.week, 5, false)
    create_time(Date.new(2000, 1, 3) + 1.week, 6, true)
    create_time(Date.new(2000, 1, 4) + 1.week, 7, true)
    create_time(Date.new(2000, 1, 3) + 2.weeks, 8, true)
    create_planning(Date.new(2000, 1, 3), 20, true)
    create_planning(Date.new(2000, 1, 3) + 3.weeks, 10, true)
    create_planning(Date.new(2000, 1, 4) + 3.weeks, 20, true)
    create_planning(Date.new(2000, 1, 5) + 3.weeks, 40, false)
    create_planning(Date.new(2000, 1, 3) + 4.weeks, 60, true)

    expected = {}
    expected[Time.utc(2000, 1, 3)] = {
      billable: 7.0,
      unbillable: 3.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    expected[Time.utc(2000, 1, 3) + 1.week] = {
      billable: 13.0,
      unbillable: 5.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    expected[Time.utc(2000, 1, 3) + 2.weeks] = {
      billable: 8.0,
      unbillable: 0.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    expected[Time.utc(2000, 1, 3) + 3.weeks] = {
      billable: 0.0,
      unbillable: 0.0,
      planned_definitive: 2.4,
      planned_provisional: 3.2
    }
    expected[Time.utc(2000, 1, 3) + 4.weeks] = {
      billable: 0.0,
      unbillable: 0.0,
      planned_definitive: 4.8,
      planned_provisional: 0.0
    }

    assert_equal expected, controlling.hours_per_week
  end

  test '#hours_per_week returns empty hash if no hours are available' do
    assert_equal({}, controlling.hours_per_week)
  end

  private

  def controlling
    @controlling ||= Order::Controlling.new(order, Date.new(2000, 1, 3) + 3.weeks)
  end

  def order
    @order ||= Fabricate(:order)
  end

  def create_time(date, hours, billable)
    Fabricate(:ordertime,
              work_item: order.work_item,
              employee: Employee.find(Employee.pluck(:id).sample),
              work_date: date,
              hours: hours,
              billable: billable)
  end

  def create_planning(date, percent, definitive)
    Fabricate(:planning,
              work_item: order.work_item,
              employee: employees(:various_pedro),
              date: date,
              percent: percent,
              definitive: definitive)
  end

end
