require 'test_helper'

module Plannings
  class BoardTest < ActiveSupport::TestCase

    test 'build rows for given plannings' do
      date = Date.today.at_beginning_of_week + 1.week
      p1 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employees(:pascal).id,
                            date: date,
                            percent: 80)
      p2 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employees(:lucien).id,
                            date: date,
                            percent: 60)
      p3 = Planning.create!(work_item_id: work_items(:hitobito_demo_site).id,
                            employee_id: employees(:lucien).id,
                            date: date + 1.weeks,
                            percent: 20)
      board = Plannings::OrderBoard.new(order, period)

      assert_equal [[employees(:lucien).id, work_items(:hitobito_demo_site).id],
                    [employees(:lucien).id, work_items(:hitobito_demo_app).id],
                    [employees(:pascal).id, work_items(:hitobito_demo_app).id]].to_set,
                   board.rows.keys.to_set

      assert_equal 20, board.work_days
      items = board.items(employees(:lucien).id, work_items(:hitobito_demo_app).id)
      assert_equal 20, items.size
      assert items.one? { |i| !i.nil? }
      assert_equal p2, items[5]
    end

    test 'sets included row' do
      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])
      assert_equal [[employees(:lucien).id, work_items(:hitobito_demo_app).id]].to_set,
                   board.rows.keys.to_set
    end

    test 'absencetimes overwrite plannings' do
      date = Date.today.at_beginning_of_week + 1.week
      p1 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employees(:pascal).id,
                            date: date,
                            percent: 80)
      p2 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employees(:lucien).id,
                            date: date,
                            percent: 60)
      p3 = Planning.create!(work_item_id: work_items(:hitobito_demo_site).id,
                            employee_id: employees(:lucien).id,
                            date: date + 1.weeks,
                            percent: 20)
      a1 = Absencetime.create!(absence_id: absences(:vacation).id,
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
      assert_equal a2, items[6]
    end

    test 'absencetimes show with default rows when no plannings are given' do
      date = Date.today.at_beginning_of_week + 1.week
      a1 = Absencetime.create!(absence_id: absences(:vacation).id,
                               employee_id: employees(:lucien).id,
                               work_date: date,
                               hours: 8,
                               report_type: 'absolute_day')
      a2 = Absencetime.create!(absence_id: absences(:vacation).id,
                               employee_id: employees(:lucien).id,
                               work_date: date + 1.day,
                               hours: 8,
                               report_type: 'absolute_day')

      board = Plannings::OrderBoard.new(order, period)
      assert board.items(employees(:lucien).id, work_items(:hitobito_demo_app).id).nil?

      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])
      assert_equal [[employees(:lucien).id, work_items(:hitobito_demo_app).id]].to_set,
                   board.rows.keys.to_set
      items = board.items(employees(:lucien).id, work_items(:hitobito_demo_app).id)
      assert_equal a1, items[5]
      assert_equal a2, items[6]
    end

    test '#week_totals are calculated for entire view, even if included rows are limited' do
      date = Date.today.at_beginning_of_week + 1.week
      p1 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employees(:pascal).id,
                            date: date,
                            percent: 100)
      p2 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employees(:lucien).id,
                            date: date,
                            percent: 100)
      p3 = Planning.create!(work_item_id: work_items(:hitobito_demo_site).id,
                            employee_id: employees(:lucien).id,
                            date: date + 1.week,
                            percent: 20)

      board = Plannings::OrderBoard.new(order, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])

      assert_equal 40.0, board.week_totals[date]
    end

    private

    def period
      start = Time.zone.now.at_beginning_of_week
      @period ||= Period.new(start, start + 4.weeks - 1.day)
    end

    def order
      orders(:hitobito_demo)
    end

  end
end