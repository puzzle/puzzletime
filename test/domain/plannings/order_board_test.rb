# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Plannings
  class OrderBoardTest < ActiveSupport::TestCase
    test 'build rows for given plannings' do
      _, p2, = create_plannings
      board = Plannings::OrderBoard.new(order, period)

      assert_equal [[employees(:lucien).id, work_items(:hitobito_demo_site).id],
                    [employees(:lucien).id, work_items(:hitobito_demo_app).id],
                    [employees(:pascal).id, work_items(:hitobito_demo_app).id]].to_set,
                   board.rows.keys.to_set

      assert_equal 20, board.work_days
      items = board.items(employees(:lucien).id, work_items(:hitobito_demo_app).id)

      assert_equal 20, items.size
      assert(items.one?(&:planning))
      assert_equal p2, items[5].planning
    end

    test 'sets included row' do
      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])

      assert_equal [[employees(:lucien).id, work_items(:hitobito_demo_app).id]].to_set,
                   board.rows.keys.to_set
    end

    test 'absencetimes can coexist with plannings' do
      create_plannings
      Absencetime.create!(absence_id: absences(:vacation).id,
                          employee_id: employees(:lucien).id,
                          work_date: date - 1.day,
                          hours: 8,
                          report_type: 'absolute_day')
      a2 = Absencetime.create!(absence_id: absences(:vacation).id,
                               employee_id: employees(:lucien).id,
                               work_date: date + 1.day,
                               hours: 8,
                               report_type: 'absolute_day')

      board = Plannings::OrderBoard.new(order, period)

      items = board.items(employees(:lucien).id, work_items(:hitobito_demo_app).id)
      items.one? { |i| !i.nil? }

      assert_equal [a2], items[6].absencetimes
    end

    test 'absencetimes show with default rows when no plannings are given' do
      a1 = Absencetime.create!(absence_id: absences(:vacation).id,
                               employee_id: employees(:lucien).id,
                               work_date: date,
                               hours: 8,
                               report_type: 'absolute_day')
      a2 = Absencetime.create!(absence_id: absences(:vacation).id,
                               employee_id: employees(:lucien).id,
                               work_date: date + 1.day,
                               hours: 6,
                               report_type: 'absolute_day')
      a3 = Absencetime.create!(absence_id: absences(:doctor).id,
                               employee_id: employees(:lucien).id,
                               work_date: date + 1.day,
                               hours: 2,
                               report_type: 'absolute_day')

      board = Plannings::OrderBoard.new(order, period)

      assert_nil board.items(employees(:lucien).id, work_items(:hitobito_demo_app).id)

      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])

      assert_equal [[employees(:lucien).id, work_items(:hitobito_demo_app).id]].to_set,
                   board.rows.keys.to_set
      items = board.items(employees(:lucien).id, work_items(:hitobito_demo_app).id)

      assert_equal [a1], items[5].absencetimes
      assert_equal [a2, a3].to_set, items[6].absencetimes.to_set
    end

    test 'no rows are returned if included rows is set to empty array' do
      create_plannings

      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([])

      assert_empty(board.rows)
    end

    test '#weekly_planned_percents are calculated for entire view, even if included rows are limited' do
      create_plannings

      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])

      assert_in_delta(40.0, board.weekly_planned_percent(date))
    end

    test '#total_row_planned_hours includes plannings from all times' do
      create_plannings
      Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                       employee_id: employees(:lucien).id,
                       date: date - 28.days,
                       percent: 100)

      board = Plannings::OrderBoard.new(order, period)

      assert_equal 16, board.total_row_planned_hours(employees(:lucien).id, work_items(:hitobito_demo_app).id)
    end

    test '#total_row_planned_hours includes plannings from only the active period if the respective flag is set' do
      create_plannings
      Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                       employee_id: employees(:lucien).id,
                       date: date - 28.days,
                       percent: 100)

      board = Plannings::OrderBoard.new(order, period, period)

      assert_equal 8, board.total_row_planned_hours(employees(:lucien).id, work_items(:hitobito_demo_app).id, true)
    end

    test '#total_post_planned_hours includes plannings for all employees, even if only some are included' do
      create_plannings
      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])

      assert_equal 20, board.total_post_planned_hours(accounting_posts(:hitobito_demo_app))
      assert_equal 0, board.total_post_planned_hours(accounting_posts(:hitobito_demo_site))
    end

    test '#total_plannable_hours are calculated for entire view, even if included rows are limited' do
      accounting_posts(:hitobito_demo_app).update!(offered_hours: 250)
      accounting_posts(:hitobito_demo_site).update!(offered_hours: 40)
      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])

      assert_in_delta(290.0, board.total_plannable_hours)
    end

    test '#total_planned_hours are calculated for entire timespan, even if included rows are limited' do
      create_plannings

      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])

      assert_equal 24, board.total_planned_hours
    end

    test '#total_planned_hours are calculated for entire timespan or only the active period, depending on the passed flag' do
      create_plannings

      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])

      assert_equal 24, board.total_planned_hours(false)
      assert_equal 20, board.total_planned_hours(true)
    end

    private

    def period
      @period ||= Period.new(date - 1.week, date + 3.weeks - 1.day)
    end

    def order
      orders(:hitobito_demo)
    end

    def date
      @date ||= Date.new(2016, 10, 10)
    end

    def create_plannings
      p1 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employees(:pascal).id,
                            date:,
                            percent: 100)
      p2 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employees(:lucien).id,
                            date:,
                            percent: 100)
      p3 = Planning.create!(work_item_id: work_items(:hitobito_demo_site).id,
                            employee_id: employees(:lucien).id,
                            date: date + 1.week,
                            percent: 50)
      [p1, p2, p3]
    end
  end
end
