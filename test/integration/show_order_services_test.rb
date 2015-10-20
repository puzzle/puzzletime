require 'test_helper'

class ShowOrderServices < ActionDispatch::IntegrationTest

  attr_reader :ordertime

  test 'click on worktime row as employee does not open edit view' do
    timeout_safe do
      create_ordertime_show_order_services_as employee_without_responsibilities
      click_worktime_row
      assert has_no_text?('Zeit bearbeiten')
      assert_equal order_order_services_path(order_id: order), current_path
    end
  end

  test 'click on worktime row as order responsible opens edit view' do
    timeout_safe do
      create_ordertime_show_order_services_as employee_responsible_for_order
      click_worktime_row
      assert has_text?('Zeit bearbeiten')
      assert_equal edit_ordertime_path(id: ordertime.id), current_path
    end
  end

  test 'click on worktime row as order responsible for different order does not open edit view' do
    timeout_safe do
      create_ordertime_show_order_services_as employee_responsible_for_different_order
      click_worktime_row
      assert has_no_text?('Zeit bearbeiten')
      assert_equal order_order_services_path(order_id: order), current_path
    end
  end

  test 'click on worktime row as management opens edit view' do
    timeout_safe do
      create_ordertime_show_order_services_as manager_not_responsible_for_any_order
      click_worktime_row
      assert has_text?('Zeit bearbeiten')
      assert_equal edit_ordertime_path(id: ordertime.id), current_path
    end
  end

  private

  def employee_without_responsibilities
    Employee.where.not(management: true, id: responsible_ids).first.tap do |employee|
      refute employee.management
      refute employee.order_responsible?
    end
  end

  def employee_responsible_for_order
    order.responsible.tap do |employee|
      refute employee.management
      assert employee.order_responsible?
      assert_equal employee, order.responsible
    end
  end

  def employee_responsible_for_different_order
    Employee.where(management: false, id: responsible_ids).where.not(id: order.responsible_id).first.tap do |employee|
      refute employee.management
      assert employee.order_responsible?
      refute_equal employee, order.responsible
    end
  end

  def manager_not_responsible_for_any_order
    Employee.where(management: true).where.not(id: order.responsible_id).first.tap do |employee|
      refute_equal employee, order.responsible
      assert employee.management
    end
  end

  def responsible_ids
    Order.select(:responsible_id).uniq.pluck(:responsible_id)
  end

  def create_ordertime(employee)
    @ordertime = Ordertime.create!(
      employee: employee,
      work_date: Time.zone.today,
      report_type: :absolute_day,
      hours: 0.5,
      description: 'some doodling',
      work_item: work_items(:hitobito_demo_app)
    )
  end

  def order
    orders(:hitobito_demo)
  end

  def click_worktime_row
    all("#ordertime_#{ordertime.id} td")[2].click
  end

  def create_ordertime_show_order_services_as(employee)
    create_ordertime employee
    login_as employee
    visit order_order_services_path(order_id: order)
  end
end
