require 'test_helper'

class OrderReportsTest < ActionDispatch::IntegrationTest

  test 'live reloads when period filter change' do
    timeout_safe do
      list_orders

      assert_no_selector('table.orders-report tbody tr')

      fill_in('start_date', with: '1.11.2006')
      fill_in('end_date', with: '') # required to lose focus on start_date
      assert_selector('table.orders-report tbody tr', count: 4)

      fill_in('end_date', with: '1.12.2006')
      fill_in('start_date', with: '2.11.2006') # required to lose focus on end_date
      assert_selector('table.orders-report tbody tr', count: 2)

    end
  end

  test 'show flash message if period filter is not valid' do
    timeout_safe do
      list_orders

      fill_in('start_date', with: '1.11.2006')
      fill_in('end_date', with: '1.10.2006')
      select('devone', from: 'department_id') # required to lose focus on end_date
      assert_selector('#flash .alert-danger')

      fill_in('end_date', with: '1.12.2006')
      select('Alle', from: 'department_id') # required to lose focus on end_date
      assert_no_selector('#flash .alert-danger')
    end
  end

  test 'changes category filter when client filter change' do
    timeout_safe do
      list_orders

      element = find("#category_work_item_id + .selectize-control")
      element.assert_no_selector('.selectize-dropdown-content .option', visible: false)

      selectize('client_work_item_id', 'Puzzle')
      element.assert_selector('.selectize-dropdown-content .option', count: 2, visible: false)
    end
  end

  private

  def list_orders
    login_as :mark
    visit reports_orders_path
  end

end
