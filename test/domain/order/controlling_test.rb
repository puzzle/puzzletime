#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class Order::ControllingTest < ActiveSupport::TestCase

  attr_reader :order, :post1, :post2

  setup do
    @order = Fabricate(:order)
    @post1 = Fabricate(:accounting_post,
                       work_item: Fabricate(:work_item, parent_id: order.work_item_id),
                       offered_hours: 100,
                       offered_rate: 100)
    @post2 = Fabricate(:accounting_post,
                       work_item: Fabricate(:work_item, parent_id: order.work_item_id),
                       offered_hours: 200,
                       offered_rate: 150)
  end

  test '#offered_total returns summed offered totals of all accounting posts' do
    assert_equal 40_000, controlling.offered_total
  end

  test '#efforts_per_week returns billable, unbillable & definitive/provisional planned efforts' do
    create_time(post1, Date.new(2000, 1, 3), 1, false)
    create_time(post1, Date.new(2000, 1, 4), 2, false)
    create_time(post1, Date.new(2000, 1, 3), 3, true)
    create_time(post2, Date.new(2000, 1, 3), 1, true) # different rate
    create_time(post1, Date.new(2000, 1, 4), 4, true)
    create_time(post1, Date.new(2000, 1, 3) + 1.week, 5, false)
    create_time(post1, Date.new(2000, 1, 3) + 1.week, 6, true)
    create_time(post1, Date.new(2000, 1, 4) + 1.week, 7, true)
    create_time(post1, Date.new(2000, 1, 3) + 2.weeks, 8, true)

    create_planning(post1, Date.new(2000, 1, 3), 20, true) # in past (ignored)
    create_planning(post1, Date.new(2000, 1, 3) + 3.weeks, 10, true)
    create_planning(post2, Date.new(2000, 1, 3) + 3.weeks, 10, true) # different rate
    create_planning(post1, Date.new(2000, 1, 4) + 3.weeks, 20, true)
    create_planning(post1, Date.new(2000, 1, 5) + 3.weeks, 40, false)
    create_planning(post1, Date.new(2000, 1, 3) + 5.weeks, 60, true)

    expected = {}
    expected[Time.utc(2000, 1, 3)] = {
      billable: 850.0,
      unbillable: 300.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    expected[Time.utc(2000, 1, 3) + 1.week] = {
      billable: 1300.0,
      unbillable: 500.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    expected[Time.utc(2000, 1, 3) + 2.weeks] = {
      billable: 800.0,
      unbillable: 0.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    expected[Time.utc(2000, 1, 3) + 3.weeks] = {
      billable: 0.0,
      unbillable: 0.0,
      planned_definitive: 240 + 120,
      planned_provisional: 320
    }
    expected[Time.utc(2000, 1, 3) + 4.weeks] = { # gap is filled with empty entry
      billable: 0.0,
      unbillable: 0.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    expected[Time.utc(2000, 1, 3) + 5.weeks] = {
      billable: 0.0,
      unbillable: 0.0,
      planned_definitive: 480,
      planned_provisional: 0.0
    }

    assert_equal expected, controlling.efforts_per_week
  end

  test '#efforts_per_week returns empty hash if no efforts are available' do
    assert_equal({}, controlling.efforts_per_week)
  end

  test '#efforts_per_week_cumulated returns cumulated efforts' do
    create_time(post1, Date.new(2000, 1, 3), 1, false)
    create_time(post1, Date.new(2000, 1, 3), 2, true)
    create_time(post1, Date.new(2000, 1, 3) + 1.week, 3, false)
    create_time(post1, Date.new(2000, 1, 3) + 1.week, 4, true)
    create_time(post1, Date.new(2000, 1, 3) + 2.weeks, 5, true)

    create_planning(post1, Date.new(2000, 1, 3) + 3.weeks, 10, true)
    create_planning(post1, Date.new(2000, 1, 5) + 3.weeks, 20, false)
    create_planning(post1, Date.new(2000, 1, 3) + 4.weeks, 30, true)

    expected = {}
    expected[Time.utc(2000, 1, 3)] = {
      billable: 200.0,
      unbillable: 100.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    expected[Time.utc(2000, 1, 3) + 1.week] = {
      billable: 600.0,
      unbillable: 400.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    expected[Time.utc(2000, 1, 3) + 2.weeks] = {
      billable: 1100.0,
      unbillable: 400.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    expected[Time.utc(2000, 1, 3) + 3.weeks] = {
      billable: 1100.0,
      unbillable: 400.0,
      planned_definitive: 80,
      planned_provisional: 160
    }
    expected[Time.utc(2000, 1, 3) + 4.weeks] = {
      billable: 1100.0,
      unbillable: 400.0,
      planned_definitive: 320,
      planned_provisional: 160
    }

    assert_equal expected, controlling.efforts_per_week_cumulated
  end

  test '#efforts_per_week_cumulated returns empty hash if no efforts are available' do
    assert_equal({}, controlling.efforts_per_week_cumulated)
  end

  private

  def controlling
    @controlling ||= Order::Controlling.new(order, Date.new(2000, 1, 3) + 3.weeks)
  end

  def create_time(accounting_post, date, hours, billable)
    Fabricate(:ordertime,
              work_item: accounting_post.work_item,
              employee: Employee.find(Employee.pluck(:id).sample),
              work_date: date,
              hours: hours,
              billable: billable)
  end

  def create_planning(accounting_post, date, percent, definitive)
    Fabricate(:planning,
              work_item: accounting_post.work_item,
              employee: employees(:various_pedro),
              date: date,
              percent: percent,
              definitive: definitive)
  end

end
