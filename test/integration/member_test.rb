# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class MemberTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    travel_to Time.zone.local(2025, 11, 1, 1, 4, 44)
    create_employments
    login
  end

  teardown do
    travel_back
  end

  test 'members absences sorted by vacations left' do
    create_absence(employees(:pascal), 8)
    create_absence(employees(:half_year_maria), 6)
    create_absence(employees(:various_pedro), 2)

    page.assert_selector('h1', text: 'Members Absenzen Übersicht')
    click_link 'Andere Zeitspanne'
    click_link 'Dieser Monat'

    assert_selector('table#evaluation thead th', count: 4)
    assert_selector('table#evaluation thead', text: "Member\tNovember    \tÜbrige Ferien")
    assert_selector('table#evaluation tbody tr', count: 3)

    assert_selector('table#evaluation tbody tr:nth-child(1)', text: "Zumkehr Pascal\t8.00 h \t29.00 Tage\t<->")
    assert_selector('table#evaluation tbody tr:nth-child(2)', text: "Dolores Maria\t6.00 h \t41.85 Tage")
    assert_selector('table#evaluation tbody tr:nth-child(3)', text: "Dolores Pedro\t2.00 h \t468.33 Tage")

    click_link 'Übrige Ferien'

    assert_selector('table#evaluation tbody tr:nth-child(1)', text: "Dolores Pedro\t2.00 h \t468.33 Tage")
    assert_selector('table#evaluation tbody tr:nth-child(2)', text: "Dolores Maria\t6.00 h \t41.85 Tage")
    assert_selector('table#evaluation tbody tr:nth-child(3)', text: "Zumkehr Pascal\t8.00 h \t29.00 Tage\t<->")
  end

  private

  def login
    login_as(:mark)
    visit(evaluator_path(evaluation: 'absences', sort: 'vacation', sort_dir: 'asc'))
  end

  def create_employments
    employees.each do |employee|
      employee.employments.create!(start_date: 1.year.ago.at_beginning_of_year,
                                   percent: 60,
                                   employment_roles_employments: [Fabricate.build(:employment_roles_employment)])
    end
  end

  def month
    (Time.zone.now.at_beginning_of_month..Time.zone.now.at_end_of_month)
  end

  def travel
    travel_to Time.zone.local(2025, 11, 1, 1, 4, 44)
  end

  def create_absence(employee, hours)
    Absencetime.create!({
                          absence_id: absences(:vacation).id,
                          employee_id: employee.id,
                          work_date: rand(month),
                          hours:,
                          report_type: 'absolute_day'
                        })
  end
end
