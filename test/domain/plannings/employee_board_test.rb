require 'test_helper'

module Plannings
  class EmployeeBoardTest < ActiveSupport::TestCase

    test '#week_totals_state is under planned if no plannings' do
      employee.employments.create!(start_date: 1.year.ago, percent: 80)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :under_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if plannings match employment' do
      create_plannings
      employee.employments.create!(start_date: 1.year.ago, percent: 80)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is over planned if plannings are greater than employment' do
      create_plannings
      employee.employments.create!(start_date: 1.year.ago, percent: 60)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :over_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if plannings match multiple employments' do
      create_plannings
      employee.employments.create!(start_date: 1.year.ago, end_date: date, percent: 40)
      employee.employments.create!(start_date: date + 1.day, percent: 90)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if plannings match last employment' do
      create_plannings
      employee.employments.create!(start_date: 1.year.ago, end_date: date + 3.days, percent: 100)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    test '#week_totals_state is fully planned if plannings match first employment' do
      create_plannings
      employee.employments.create!(start_date: date + 1.day, percent: 100)
      board = Plannings::EmployeeBoard.new(employee, period)
      assert_equal :fully_planned, board.week_totals_state(date)
    end

    private

    def period
      start = Time.zone.now.at_beginning_of_week
      @period ||= Period.new(start, start + 4.weeks - 1.day)
    end

    def employee
      employees(:lucien)
    end

    def date
      @date ||= Date.today.at_beginning_of_week + 1.week
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