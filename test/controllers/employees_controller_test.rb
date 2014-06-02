require 'test_helper'

class EmployeesControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  def not_existing
    # run this method for disabled tests
  end

  [:test_show,
   :test_show_json,
   :test_new,
   :test_create,
   :test_create_json,
   :test_destroy,
   :test_destroy_json].each do |m|
     alias_method m, :not_existing
   end

  private

  # Test object used in several tests.
  def test_entry
    employees(:pascal)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { initial_vacation_days: 5,
      management: false }
  end
end
