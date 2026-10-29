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
    Settings.meal_compensation.active = true
    visit order_order_cost_path(order_id: order.id)

    assert_selector(:css, '#cost_type')
    assert has_css?('#expenses-list')
    assert has_css?('#meal-compensations-list')

    select('Spesen', from: 'cost_type')

    assert has_css?('#expenses-list')
    assert has_no_css?('#meal-compensations-list')

    select('Verpflegungsentschädigung', from: 'cost_type')

    assert has_no_css?('#expenses-list')
    assert has_css?('#meal-compensations-list')
  end

  test 'with meal_compensations deacivated, expenses are shown and no select field is present' do
    Settings.meal_compensation.active = false
    visit order_order_cost_path(order_id: order.id)

    assert_no_selector(:css, '#cost_type')
    assert has_css?('#expenses-list')
    assert has_no_css?('#meal-compensations-list')
  end

  test 'all meal compensation days are visible' do
    Settings.meal_compensation.active = true

    create_ordertime(employees(:mark), 5, 1.week.ago)
    create_ordertime(employees(:mark), 2, 2.days.ago)
    create_ordertime(employees(:mark), 2, 2.days.ago)
    create_ordertime(employees(:pascal), 2, 2.days.ago)

    visit order_order_cost_path(order_id: order.id, cost_type: 'meal_compensation')

    mark_meal_compensation_days = page.find("#employee_#{employees(:mark).id}").all('td').last.text

    assert_equal '2', mark_meal_compensation_days

    pascal_meal_compensation_days = page.find("#employee_#{employees(:pascal).id}").all('td').last.text

    assert_equal '0', pascal_meal_compensation_days
  end

  private

  def create_ordertime(employee, hours, work_date)
    @ordertime = Ordertime.create!(
      employee:,
      work_date:,
      report_type: :absolute_day,
      hours:,
      description: 'inventing the next big thing (with eyes closed in the chill-room)',
      work_item:,
      meal_compensation: true
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
  end
end
