require 'test_helper'

class ShowOrderServices < ActionDispatch::IntegrationTest
  test 'click on worktime row as employee does not open edit view' do
    timeout_safe do
      show_order_services_as :pascal
      all("#ordertime_6 td")[2].click
      assert has_no_text?("Zeit bearbeiten")
      assert_equal order_order_services_path(order_id: orders(:puzzletime)), current_path
    end
  end

  test 'click on worktime row as employee opens edit view' do
    timeout_safe do
      show_order_services_as :lucien
      all("#ordertime_6 td")[2].click
      assert has_text?("Zeit bearbeiten")
      assert_equal edit_ordertime_path(id: 6), current_path
    end
  end

  test 'click on worktime row as management opens edit view' do
    timeout_safe do
      show_order_services_as :mark
      all("#ordertime_10 td")[2].click
      assert has_text?("Zeit bearbeiten")
      assert_equal edit_ordertime_path(id: 10), current_path
    end
  end

  private

  def show_order_services_as(employee)
    login_as employee
    visit order_order_services_path(order_id: orders(:puzzletime))
  end
end