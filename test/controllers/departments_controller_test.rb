# encoding: UTF-8

require 'test_helper'

class DepartmentsControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  def test_destroy
    @test_entry = Department.create!(name: 'test', shortname: 'te')
    super
  end

  def test_destroy_json
    @test_entry = Department.create!(name: 'test', shortname: 'te')
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
    @test_entry ||= departments(:devone)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { name: '/dev/tre',
      shortname: 'D3' }
  end
end
