# encoding: UTF-8

require 'test_helper'

class OvertimeVacationsControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  private

  # Test object used in several tests.
  def test_entry
    overtime_vacations(:pascal_1)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { employee_id: 6,
      hours: 40,
      transfer_date: Time.zone.today }
  end
end
