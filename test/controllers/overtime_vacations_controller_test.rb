require 'test_helper'

class OvertimeVacationsControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login


  private

  # Test object used in several tests.
  def test_entry
    overtime_vacations(:pascal_1)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { employee_id: 6,
      hours: 40,
      transfer_date: Date.today }
  end
end
