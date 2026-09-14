# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class EvaluatorHelperTest < ActionView::TestCase
  include FormatHelper

  test 'vacations is bound to the chosen Stichtag, not silently to year-end' do
    employee = Fabricate(:employee, initial_vacation_days: 0, department: Department.first)
    employee.employments.create!(start_date: Date.new(2020, 1, 1), end_date: nil,
                                 percent: 100, vacation_days_per_year: 25,
                                 employment_roles_employments: [Fabricate.build(:employment_roles_employment)])

    stichtag = Date.new(2026, 6, 30)
    @period = Period.new(Date.new(2026, 1, 1), stichtag)

    before = vacations(employee)

    # Booking a vacation absence AFTER the chosen Stichtag must not change an
    # export already scoped to that Stichtag.
    vacation_absence = Absence.where(vacation: true).first
    Worktime.create!(absence: vacation_absence, employee:, work_date: Date.new(2026, 8, 24),
                     hours: 8, report_type: 'absolute_day')

    assert_equal before, vacations(employee)
    assert_equal format_days(employee.statistics.remaining_vacations(stichtag), true), vacations(employee)
  end

  test 'vacations is bound to a future Stichtag too, not silently to that year-end' do
    employee = Fabricate(:employee, initial_vacation_days: 0, department: Department.first)
    employee.employments.create!(start_date: Date.new(2020, 1, 1), end_date: nil,
                                 percent: 100, vacation_days_per_year: 25,
                                 employment_roles_employments: [Fabricate.build(:employment_roles_employment)])

    stichtag = Date.new(2027, 3, 31) # in the future relative to today
    @period = Period.new(Date.new(2027, 1, 1), stichtag)

    before = vacations(employee)

    # Booking a vacation absence after the future Stichtag (but still within
    # that Stichtag's year) must not change an export scoped to the Stichtag.
    vacation_absence = Absence.where(vacation: true).first
    Worktime.create!(absence: vacation_absence, employee:, work_date: Date.new(2027, 6, 15),
                     hours: 8, report_type: 'absolute_day')

    assert_equal before, vacations(employee)
    assert_equal format_days(employee.statistics.remaining_vacations(stichtag), true), vacations(employee)
  end
end
