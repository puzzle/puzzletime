# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class ShowOrderCost < ActionDispatch::IntegrationTest
  setup :login
  attr_reader :ordertime

  test 'selecting cost type shows respective table' do
    timeout_safe do
      activate_meal_compensations

      assert_selector(:css, '#cost_type')
      assert has_no_css?('#expenses_list')
      assert has_no_css?('#meal_compensations_list')

      select('Spesen', from: 'cost_type')

      assert has_css?('#expenses_list')
      assert has_no_css?('#meal_compensations_list')

      select('Verpflegungsentschädigung', from: 'cost_type')

      assert has_no_css?('#expenses_list')
      assert has_css?('#meal_compensations_list')
    end
  end

  test 'with meal_compensations deacivated, expenses are shown and no select field' do
    timeout_safe do
      deactivate_meal_compensations

      assert_no_selector(:css, '#cost_type')
      assert has_css?('#expenses_list')
      assert has_no_css?('#meal_compensations_list')
    end
  end

  test 'all meal compensation days are visible' do
    timeout_safe do
      activate_meal_compensations

      create_ordertime(employees(:mark), 5, 1.week.ago, true)
      create_ordertime(employees(:mark), 2, 2.days.ago, true)
      create_ordertime(employees(:mark), 2, 2.days.ago, true)
      create_ordertime(employees(:pascal), 2, 2.days.ago, true)

      visit order_order_cost_path(order_id: order.id, cost_type: 'meal_compensation')

      mark_meal_compensation_days = page.find("#employee_#{employees(:mark).id}").all('td').last.text

      assert_equal '2', mark_meal_compensation_days

      pascal_meal_compensation_days = page.find("#employee_#{employees(:pascal).id}").all('td').last.text

      assert_equal '0', pascal_meal_compensation_days
    end
  end

  private

  def create_ordertime(employee, hours, work_date, meal_compensation)
    @ordertime = Ordertime.create!(
      employee:,
      work_date:,
      report_type: :absolute_day,
      hours:,
      description: 'inventing the next big thing (with eyes closed in the chill-room)',
      work_item:,
      meal_compensation:
    )
  end

  def work_item
    work_items(:hitobito_demo_app)
  end

  def order
    orders(:hitobito_demo)
  end

  def login
    login_as(:mark)
    visit order_order_cost_path(order_id: order.id)
  end

  def activate_meal_compensations
    Settings.meal_compensation.active = true
  end

  def deactivate_meal_compensations
    Settings.meal_compensation.active = false
  end
end
