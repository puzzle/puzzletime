#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class EmploymentsControllerTest < ActionController::TestCase
  include CrudControllerTestHelper

  setup :login

  not_existing :test_show,
               :test_show_json,
               :test_show_with_non_existing_id_raises_record_not_found

  def test_update
    test_entry.employment_roles_employments.delete_all
    super
  end

  def test_overlapping
    assert_equal Date.new(2006, 12, 31), employments(:for_half_year).end_date
    post :create, params: { employment: { percent: 80,
                                employment_roles_employments_attributes: {
                                  '0' => test_employment_role_80
                                },
                                start_date: Date.new(2006, 10, 1),
                                end_date: Date.new(2007, 5, 31) }, employee_id: 1 }
    assert_response :unprocessable_entity
    assert response.body.include? 'Für diese Zeitspanne ist bereits eine andere Anstellung definiert'
  end

  def test_employment_percent
    post :create, params: { employment: { percent: 60,
                                employment_roles_employments_attributes: {
                                  '0' => test_employment_role_80
                                },
                                start_date: Date.new(2008, 10, 1),
                                end_date: Date.new(2009, 5, 31) }, employee_id: 1 }
    assert_response :unprocessable_entity
    assert response.body.include? 'Funktionsanteile und Beschäftigungsgrad stimmen nicht überein.'
  end

  def test_employment_role_uniqueness
    post :create, params: { employment: { percent: 160,
                                employment_roles_employments_attributes: {
                                  '0' => test_employment_role_80,
                                  '1' => test_employment_role_80
                                },
                                start_date: Date.new(2008, 10, 1),
                                end_date: Date.new(2009, 5, 31) }, employee_id: 1 }
    assert_response :unprocessable_entity
    assert response.body.include? 'Funktionen können nicht doppelt erfasst werden.'
  end

  def test_prefill_from_newest_employment
    get :new, params: { employee_id: employees(:various_pedro) }
    assert_equal 100, assigns(:employment).percent
    assert_equal 1, assigns(:employment).employment_roles_employments.length
  end

  private

  # Test object used in several tests.
  def test_entry
    employments(:left_this_year)
  end

  # Attribute hash used in several tests.
  def test_entry_attrs
    { percent: 80,
      employment_roles_employments_attributes: {
        '0' => test_employment_role_80
      },
      start_date: Time.zone.today - 1.year,
      end_date: Time.zone.today,
      comment: 'bla bla' }
  end

  def test_employment_role_80
    { employment_role_id: employment_roles(:software_engineer).id,
      employment_role_level_id: employment_role_levels(:junior).id,
      percent: 80 }
  end
end
