# encoding: UTF-8

require 'test_helper'

class EmployeesControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  def test_destroy
    @test_entry = Fabricate(:employee)
    super
  end

  def test_destroy_json
    @test_entry = Fabricate(:employee)
    super
  end

  def test_destroy_protected
    assert_no_difference("#{model_class.name}.count") do
      delete :destroy, test_params(id: test_entry.id)
    end
    assert_redirected_to_index
  end

  private

  # Test object used in several tests.
  def test_entry
    @test_entry ||= employees(:pascal)
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
