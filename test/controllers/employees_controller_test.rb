# encoding: UTF-8

require 'test_helper'

class EmployeesControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  def test_destroy
    assert_raises(RuntimeError) do
      super
    end
  end

  def test_destroy_json
    assert_raises(RuntimeError) do
      super
    end
  end

  private

  # Test object used in several tests.
  def test_entry
    employees(:pascal)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { firstname: 'Franz',
      lastname: 'Muster',
      shortname: 'fm',
      email: 'muster@puzzle.ch',
      ldapname: 'fmuster',
      initial_vacation_days: 5,
      management: false }
  end
end
