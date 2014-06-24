require 'test_helper'

class EmploymentsControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  private

  # Test object used in several tests.
  def test_entry
    employments(:left_this_year)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { percent: 80,
      start_date: Date.today - 1.year,
      end_date: Date.today }
  end
end
