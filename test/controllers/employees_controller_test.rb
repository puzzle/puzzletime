# encoding: UTF-8

require 'test_helper'

class EmployeesControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  teardown -> { Crm.instance = nil }

  def test_show_with_crm_existing_profile
    Crm.instance = Crm::Base.new
    Crm.instance.expects(:find_people_by_email).with(test_entry.email).returns([OpenStruct.new(id: 123)])
    Crm.instance.expects(:contact_url).with(123).returns('http://example.com/profile-123')

    get :show, test_params(id: test_entry.id)
    assert_redirected_to('http://example.com/profile-123')
  end

  def test_show_with_crm_missing_profile
    Crm.instance = Crm::Base.new
    Crm.instance.expects(:find_people_by_email).with(test_entry.email).returns([])

    get :show, test_params(id: test_entry.id)
    assert_response :success
    assert_template 'show'
    assert_equal test_entry, entry
    assert_equal "Person mit Email '#{test_entry.email}' nicht gefunden in CRM.", flash[:alert]
  end

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
