# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class OrderReportsTest < ActionDispatch::IntegrationTest
  test 'live reloads when period filter change' do
    timeout_safe do
      list_orders

      assert_no_selector('table.orders-report tbody tr')

      fill_in('start_date', with: '1.11.2006')
      fill_in('end_date', with: ' ') # required to lose focus on start_date

      assert_selector('table.orders-report tbody tr', count: 4)

      fill_in('end_date', with: '1.12.2006')
      fill_in('start_date', with: '2.11.2006') # required to lose focus on end_date

      assert_selector('table.orders-report tbody tr', count: 2)
    end
  end

  test 'clear timespan when period shortcut selected' do
    timeout_safe do
      list_orders

      fill_in('start_date', with: '1.11.2006')

      assert_equal '1.11.2006', page.find('#start_date')[:value]

      select('Dieser Monat', from: 'period_shortcut')

      sleep 0.2 # give time to JS to disable the fields and clear the previous input

      assert page.find('#start_date')[:disabled]
      assert page.find('#end_date')[:disabled]

      assert_predicate page.find('#start_date')[:value], :blank?

      select('benutzerdefiniert', from: 'period_shortcut')

      sleep 0.2

      assert_not page.find('#start_date')[:disabled]
      assert_not page.find('#end_date')[:disabled]
    end
  end

  test 'show flash message if period filter is not valid' do
    timeout_safe do
      list_orders

      fill_in('start_date', with: '1.11.2006')
      fill_in('end_date', with: '1.10.2006')
      select('Rot', from: 'target') # required to lose focus on end_date

      assert_selector('#flash .alert-danger')

      fill_in('end_date', with: '1.12.2006')
      select('Orange', from: 'target') # required to lose focus on end_date

      assert_no_selector('#flash .alert-danger')
    end
  end

  test 'changes category filter when client filter change' do
    timeout_safe do
      list_orders

      element = find('#category_work_item_id + .selectize-control')

      element.assert_no_selector('.selectize-dropdown-content .option', visible: false)

      selectize('client_work_item_id', 'Puzzle')

      element.assert_selector('.selectize-dropdown-content .option', count: 2, visible: false)
    end
  end

  test 'passing no params will initialize the listing with default params' do
    timeout_safe do
      login_as :pascal
      visit reports_orders_path

      assert has_select?('period_shortcut', selected: 'Dieser Monat')
      assert_equal find('#department_id', visible: :all).value, [employees(:pascal).department.id.to_s]
    end

    timeout_safe do
      login_as :pascal
      visit reports_orders_path(status_preselection: 'closed')

      assert has_select?('period_shortcut', selected: 'Letztes Quartal')
      assert_equal find('#department_id', visible: :all).value, [employees(:pascal).department.id.to_s]
    end

    timeout_safe do
      login_as :pascal
      visit reports_orders_path(status_preselection: 'not_closed')

      assert has_select?('period_shortcut', selected: 'Dieser Monat')
      assert_equal find('#department_id', visible: :all).value, [employees(:pascal).department.id.to_s]
      assert_equal find('#status_id', visible: :all).value, OrderStatus.where(default: true).pluck(:id).map(&:to_s)
    end
  end

  private

  def list_orders
    login_as :mark
    visit reports_orders_path(period_shortcut: '', responsible_id: '')
  end
end
