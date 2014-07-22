# encoding: UTF-8

require 'test_helper'

class EmployeesControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found,
               :test_new,
               :test_create,
               :test_create_json,
               :test_destroy,
               :test_destroy_json

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
