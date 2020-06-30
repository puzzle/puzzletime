#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class ListOrdersTest < ActionDispatch::IntegrationTest
  test 'list orders as employee has no create link' do
    timeout_safe do
      list_orders_as :pascal
      assert has_no_link?('Erstellen')
    end
  end

  test 'list orders as order responsible member has create link' do
    timeout_safe do
      list_orders_as :lucien
      assert has_link?('Erstellen')
    end
  end

  test 'list orders as management has create link' do
    timeout_safe do
      list_orders_as :mark
      assert has_link?('Erstellen')
    end
  end

  test 'list orders filters list by name' do
    timeout_safe do
      list_orders_as :mark
      assert page.has_selector?('table.orders-list tbody tr', count: 3)
      fill_in 'Name', with: 'swiss'
      page.find('input#q').native.send_keys(:enter)
      assert page.has_selector?('table.orders-list tbody tr', count: 1)
      find('.has-clear [data-clear]').click
      assert page.has_selector?('table.orders-list tbody tr', count: 3)
    end
  end

  private

  def list_orders_as(employee)
    login_as employee
    visit orders_path
  end
end
