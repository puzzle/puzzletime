# encoding: UTF-8
require 'test_helper'

class EmploymentsControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  def test_overlapping
    assert_equal Date.new(2006, 12, 31), employments(:for_half_year).end_date
    post :create, employment: { percent: 100,
                               start_date: Date.new(2006, 10, 1),
                               end_date: Date.new(2007, 5, 31)}, employee_id: employees(:half_year_maria).id
    assert response.body.include? "Für diese Zeitspanne ist bereits eine andere Anstellung definiert"
  end


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
