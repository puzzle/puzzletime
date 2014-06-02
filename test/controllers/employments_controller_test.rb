require 'test_helper'

class EmploymentsControllerTest < ActionController::TestCase

  #include CrudControllerTestHelper

  setup :login

  def test_index # :nodoc:
    get :index, employee_id: 2
    assert_response :success
    assert_template 'index'
    assert entries.present?
  end

  def test_index_json # :nodoc:
    get :index, employee_id: 2, format: 'json'
    assert_response :success
    assert entries.present?
    assert @response.body.starts_with?('[{'), @response.body
  end

  private

  # The entries as set by the controller.
  def entries
    @controller.send(:entries)
  end

  # Test object used in several tests.
  def test_entry
    employments(:various_20)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { percent: 80,
      start_date: Date.today - 1.year,
      end_date: Date.today }
  end
end
