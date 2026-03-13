# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class CreateEmploymentTest < ActionDispatch::IntegrationTest
  setup :init_view

  test 'new employment' do
    page.assert_selector('tbody tr', count: 1)
    click_link 'Erstellen'

    page.assert_selector('h1', text: "Anstellung von #{employee.lastname} #{employee.firstname} erstellen")

    fill_in 'employment_start_date', with: Date.current
    fill_in 'employment_end_date', with: Date.current + 1
    accept_confirm('Möglicherweise ging vergessen die Ferientage pro Jahr einzutragen. Dennoch fortfahren?') do
      click_button 'Speichern'
    end

    assert_current_path(
      "#{employee_employments_path(employee)}?returning=true",
      ignore_query: false
    )

    page.assert_selector('tbody tr', count: 2)
  end

  private

  def employee
    @employee ||= Fabricate(:employee, management: true)
  end

  def init_view
    _employment = Fabricate(:employment, employee:, start_date: 2.years.ago.to_date, end_date: 1.day.ago.to_date, percent: 80, vacation_days_per_year: 27)
    login_as employee
    visit employee_employments_path(employee)
  end
end
