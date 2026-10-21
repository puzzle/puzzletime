# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class PlanningsCompanyTest < ActionDispatch::IntegrationTest
  setup { login_as :mark }

  # css_select instead of assert_select: with Capybara's assertions mixed in, assert_select looks for a
  # select box by locator instead of matching a CSS selector.
  test 'employee planning page does not show company filters' do
    get plannings_employee_path(employees(:mark))

    assert_response :success
    assert_empty css_select('select[name="custom_list_ids[]"]')
  end

  test 'company page shows all filters' do
    get plannings_company_path

    assert_response :success
    ['select[name="custom_list_ids[]"]', 'select[name="department_id"]', 'select[name="member_coach_id"]',
     'input[type="checkbox"][name="include_provisional"]'].each do |selector|
      assert_not_empty css_select(selector), selector
    end
  end
end
