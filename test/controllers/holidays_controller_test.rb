# encoding: UTF-8

require 'test_helper'

class HolidaysControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  private

  # Test object used in several tests.
  def test_entry
    holidays(:pfingstmontag)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { holiday_date: Time.zone.today,
      musthours_day: 0 }
  end
end
