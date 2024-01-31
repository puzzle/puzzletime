#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class EmployeesControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  teardown -> { Crm.instance = nil }

  def test_settings
    get :settings, params: test_params(id: test_entry.id)

    assert_response :success
    assert_template 'employees/settings'
    assert_attrs_equal test_entry.attributes.slice(:worktimes_commit_reminder, :eval_periods)
  end

  def test_update_settings
    assert_no_difference("#{model_class.name}.count") do
      put :update_settings, params: test_params(id: test_entry.id,
                                                model_identifier => test_settings_attrs)

      assert_empty entry.errors.full_messages
    end
    assert_attrs_equal(test_settings_attrs)
    assert_redirected_to root_path
  end

  def test_show_with_crm_existing_profile
    Crm.instance = Crm::Base.new
    Crm.instance.expects(:find_people_by_email).with(test_entry.email).returns([OpenStruct.new(id: 123)])
    Crm.instance.expects(:contact_url).with(123).returns('http://example.com/profile-123')

    get :show, params: test_params(id: test_entry.id)

    assert_redirected_to('http://example.com/profile-123')
  end

  def test_show_with_crm_missing_profile
    Crm.instance = Crm::Base.new
    Crm.instance.expects(:find_people_by_email).with(test_entry.email).returns([])

    get :show, params: test_params(id: test_entry.id)

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
      delete :destroy, params: test_params(id: test_entry.id)
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
      management: false,
      department_id: departments(:devone).id,
      probation_period_end_date: Date.new(2015, 10, 3),
      nationalities: ['CH', 'DE'] }
  end

  def test_settings_attrs
    {
      worktimes_commit_reminder: false,
      eval_periods: ['-1m', '0']
    }
  end
end
