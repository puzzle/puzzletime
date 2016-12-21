require 'test_helper'

module Plannings
  class EmployeeBoardTest < ActiveSupport::TestCase

    setup { Holiday.clear_cache }

    test '#week_planning_state is nil if no plannings' do
      employee.employments.create!(start_date: date - 1.year, percent: 80)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal nil, board.week_planning_state(date)
    end

    test '#week_planning_state is fully planned if no plannings and unpaid absence' do
      employee.employments.create!(start_date: date - 1.year, percent: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_planning_state(date)
    end

    test '#week_planning_state is fully planned if no plannings and all-week holiday' do
      employee.employments.create!(start_date: date - 1.year, percent: 100)
      5.times { |i| Holiday.create!(holiday_date: date + i.days, musthours_day: 0) }
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_planning_state(date)
    end

    test '#week_planning_state is fully planned if absencetimes match employment' do
      employee.employments.create!(start_date: date - 1.year, percent: 100)
      Absencetime.create!(work_date: date, hours: 40, employee: employee, absence: absences(:vacation))
      Absencetime.create!(work_date: date + 7, hours: 8, employee: employee, absence: absences(:vacation))
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_planning_state(date)
    end

    test '#week_planning_state is fully planned if plannings match employment' do
      create_plannings
      employee.employments.create!(start_date: date - 1.year, percent: 80)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_planning_state(date)
    end

    test '#week_planning_state is over planned if plannings are greater than employment' do
      create_plannings
      employee.employments.create!(start_date: date - 1.year, percent: 60)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :over_planned, board.week_planning_state(date)
    end

    test '#week_planning_state is fully planned if plannings match multiple employments' do
      create_plannings
      employee.employments.create!(start_date: date - 1.year, end_date: date, percent: 40)
      employee.employments.create!(start_date: date + 1.day, percent: 90)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_planning_state(date)
    end

    test '#week_planning_state is fully planned if plannings match last employment' do
      create_plannings
      employee.employments.create!(start_date: date - 1.year, end_date: date + 3.days, percent: 100)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_planning_state(date)
    end

    test '#week_planning_state is fully planned if plannings match first employment' do
      create_plannings
      employee.employments.create!(start_date: date + 1.day, percent: 100)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_planning_state(date)
    end

    test '#weekly_planned_percent includes absences' do
      create_plannings
      Absencetime.create!(work_date: date + 4.days,
                          hours: 4,
                          employee_id: employee.id,
                          absence: absences(:doctor))
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 90, board.weekly_planned_percent(date)
    end

    test '#weekly_planned_percent includes regular holidays' do
      @date = Date.new(2014, 12, 22)
      employee.employments.create!(start_date: date - 1.year, percent: 80)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 32, board.weekly_planned_percent(date)
    end

    test '#weekly_planned_percent includes irregular holidays' do
      employee.employments.create!(start_date: date - 1.year, percent: 100)
      Holiday.create!(holiday_date: date + 1.day, musthours_day: 6)
      Holiday.create!(holiday_date: date + 2.days, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 25, board.weekly_planned_percent(date)
    end

    test '#weekly_planned_percent includes holidays on employment changes' do
      employee.employments.create!(start_date: date - 1.year, percent: 100)
      employee.employments.create!(start_date: date + 3.days, percent: 60)
      Holiday.create!(holiday_date: date + 2.days, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 20, board.weekly_planned_percent(date)
    end

    test '#weekly_planned_percent excludes holidays before first employment' do
      employee.employments.create!(start_date: date + 2.days, percent: 80)
      Holiday.create!(holiday_date: date, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 0, board.weekly_planned_percent(date)
    end

    test '#weekly_planned_percent includes holidays after first employment' do
      employee.employments.create!(start_date: date + 2.days, percent: 80)
      Holiday.create!(holiday_date: date + 4.days, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 16, board.weekly_planned_percent(date)
    end

    test '#weekly_planned_percent excludes holidays after final employment' do
      employee.employments.create!(start_date: date - 1.year, end_date: date + 1.day, percent: 80)
      employee.employments.create!(start_date: date + 1.year, percent: 80)
      Holiday.create!(holiday_date: date + 4.days, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 0, board.weekly_planned_percent(date)
    end

    test '#weekly_employment_percent respects unpaid holidays' do
      employee.employments.create!(start_date: date - 1.year, percent: 100)
      employee.employments.create!(start_date: date + 2.days, percent: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 40, board.weekly_employment_percent(date)
    end

    test '#total_row_planned_hours includes only plannings for period' do
      create_plannings
      Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                       employee_id: employee.id,
                       date: date - 28.days,
                       percent: 100)
      Absencetime.create!(work_date: date + 4.days,
                          hours: 4,
                          employee_id: employee.id,
                          absence: absences(:doctor))
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 24, board.total_row_planned_hours(employee.id, work_items(:hitobito_demo_app).id)
    end

    test '#total_planned_hours includes plannings plus absencetimes' do
      create_plannings
      Absencetime.create!(work_date: date + 4.days,
                          hours: 4,
                          employee_id: employee.id,
                          absence: absences(:doctor))
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 40, board.total_planned_hours
    end

    test '#total_planned_hours is for all employee work items, even if included rows are limited' do
      create_plannings
      board = Plannings::EmployeeBoard.new(employee, period)
      board.for_rows([[employees(:lucien).id, work_items(:hitobito_demo_app).id]])
      assert_equal 36, board.total_planned_hours
    end

    test '#total_plannable_hours includes employement minus holidays' do
      employee.employments.create!(start_date: date - 1.year, percent: 80)
      Holiday.create!(holiday_date: date + 2.days, musthours_day: 6)
      Holiday.create!(holiday_date: date + 3.days, musthours_day: 0)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal 120, board.total_plannable_hours
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