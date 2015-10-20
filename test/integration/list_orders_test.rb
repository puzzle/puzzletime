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

  private

  def list_orders_as(employee)
    login_as employee
    visit orders_path
  end
end
