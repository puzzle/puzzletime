require 'test_helper'

class HolidaysControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login


  private

  # Test object used in several tests.
  def test_entry
    holidays(:pfingstmontag)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { holiday_date: Date.today,
      musthours_day: 0 }
  end
end
