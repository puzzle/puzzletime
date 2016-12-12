require 'test_helper'

module Plannings
  class EmployeeBoardTest < ActiveSupport::TestCase

    setup { Holiday.clear_cache }

    test '#week_totals_state is nil if no plannings' do
      employee.employments.create!(start_date: date - 1.year, percent: 80)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal nil, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if no plannings and unpaid absence' do
      employee.employments.create!(start_date: date - 1.year, percent: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if no plannings and all-week holiday' do
      employee.employments.create!(start_date: date - 1.year, percent: 100)
      5.times { |i| Holiday.create!(holiday_date: date + i.days, musthours_day: 0) }
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if absencetimes match employment' do
      employee.employments.create!(start_date: date - 1.year, percent: 100)
      Absencetime.create!(work_date: date, hours: 40, employee: employee, absence: absences(:vacation))
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if plannings match employment' do
      create_plannings
      employee.employments.create!(start_date: date - 1.year, percent: 80)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is over planned if plannings are greater than employment' do
      create_plannings
      employee.employments.create!(start_date: date - 1.year, percent: 60)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :over_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if plannings match multiple employments' do
      create_plannings
      employee.employments.create!(start_date: date - 1.year, end_date: date, percent: 40)
      employee.employments.create!(start_date: date + 1.day, percent: 90)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if plannings match last employment' do
      create_plannings
      employee.employments.create!(start_date: date - 1.year, end_date: date + 3.days, percent: 100)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if plannings match first employment' do
      create_plannings
      employee.employments.create!(start_date: date + 1.day, percent: 100)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    test '#week_total includes absences' do
      create_plannings
      Absencetime.create!(work_date: date + 4.days,
                          hours: 4,
                          employee_id: employee.id,
                          absence: absences(:doctor))
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 90, board.week_total(date)
    end

    test '#week_total includes regular holidays' do
      @date = Date.new(2014, 12, 22)
      employee.employments.create!(start_date: date - 1.year, percent: 80)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 32, board.week_total(date)
    end

    test '#week_total includes irregular holidays' do
      employee.employments.create!(start_date: date - 1.year, percent: 100)
      Holiday.create!(holiday_date: date + 1.day, musthours_day: 6)
      Holiday.create!(holiday_date: date + 2.days, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 25, board.week_total(date)
    end

    test '#week_total includes holidays on employment changes' do
      employee.employments.create!(start_date: date - 1.year, percent: 100)
      employee.employments.create!(start_date: date + 3.days, percent: 60)
      Holiday.create!(holiday_date: date + 2.days, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 20, board.week_total(date)
    end

    test '#week_total excludes holidays before first employment' do
      employee.employments.create!(start_date: date + 2.days, percent: 80)
      Holiday.create!(holiday_date: date, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 0, board.week_total(date)
    end

    test '#week_total includes holidays after first employment' do
      employee.employments.create!(start_date: date + 2.days, percent: 80)
      Holiday.create!(holiday_date: date + 4.days, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 16, board.week_total(date)
    end

    test '#week_total excludes holidays after final employment' do
      employee.employments.create!(start_date: date - 1.year, end_date: date + 1.day, percent: 80)
      employee.employments.create!(start_date: date + 1.year, percent: 80)
      Holiday.create!(holiday_date: date + 4.days, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 0, board.week_total(date)
    end

    test '#weekly_employment_percent respects unpaid holidays' do
      employee.employments.create!(start_date: date - 1.year, percent: 100)
      employee.employments.create!(start_date: date + 2.days, percent: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 40, board.weekly_employment_percent(date)
    end

    test '#total_hours includes plannings plus absencetimes' do
      create_plannings
      Absencetime.create!(work_date: date + 4.days,
                          hours: 4,
                          employee_id: employee.id,
                          absence: absences(:doctor))
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 40, board.total_hours
    end

    test '#plannable_hours includes employement minus holidays' do
      employee.employments.create!(start_date: date - 1.year, percent: 80)
      Holiday.create!(holiday_date: date + 2.days, musthours_day: 6)
      Holiday.create!(holiday_date: date + 3.days, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 120, board.plannable_hours
    end

    private

    def period
      @period ||= Period.new(date - 1.week, date + 3.weeks - 1.day)
    end

    def employee
      employees(:lucien)
    end

    def date
      @date ||= Date.new(2016, 10, 10)
    end

    def create_plannings
      p1 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employee.id,
                            date: date,
                            percent: 100)
      p2 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employee.id,
                            date: date + 1.day,
                            percent: 100)
      p3 = Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                            employee_id: employee.id,
                            date: date + 2.days,
                            percent: 100)
      p4 = Planning.create!(work_item_id: work_items(:hitobito_demo_site).id,
                            employee_id: employee.id,
                            date: date + 3.days,
                            percent: 100)
      p5 = Planning.create!(work_item_id: work_items(:hitobito_demo_site).id,
                            employee_id: employee.id,
                            date: date + 1.weeks,
                            percent: 50)
      [p1, p2, p3, p4, p5]
    end


  end
end