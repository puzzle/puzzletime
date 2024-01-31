#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class PlanningsEmployeesTest < ActionDispatch::IntegrationTest
  setup :list_plannings

  test 'create and update planning entries' do
    page.assert_selector('.planning-calendar .-definitive', count: 0)
    page.assert_selector('.planning-calendar .-provisional', count: 0)
    page.assert_selector('.planning-calendar .-selected', count: 0)
    all('.planning-calendar-week')[0].assert_text('0%')
    all('.planning-calendar-week')[1].assert_text('0%')
    page.assert_selector('.planning-panel', visible: false)

    page.assert_no_selector(row_selector)
    find('.add').click

    selectize('add_work_item_select_id', 'PITC-PT: PuzzleTime', no_click: true)

    page.assert_selector(row_selector, text: 'PITC-PT: PuzzleTime')

    row.all('.day')[0].assert_text('')
    drag(row.all('.day')[0], row.all('.day')[4])

    page.assert_selector('.planning-calendar .-selected', count: 5)
    page.assert_selector('.planning-panel', visible: true)

    within '.planning-panel' do
      fill_in 'percent', with: '50'
      click_button 'fix'
      click_button 'OK'
    end

    page.assert_selector('.planning-calendar .-definitive', count: 5)
    page.assert_selector('.planning-calendar .-provisional', count: 0)
    page.assert_selector('.planning-calendar .-selected', count: 0)
    all('.planning-calendar-week')[0].assert_text('50%')
    all('.planning-calendar-week')[1].assert_text('0%')
    page.assert_selector('.planning-panel', visible: false)
    assert_percents ['50', '50', '50', '50', '50', '', '', ''], row

    drag(row.all('.day')[3], row.all('.day')[6])

    page.assert_selector('.planning-calendar .-selected', count: 4)
    page.assert_selector('.planning-panel', visible: true)

    within '.planning-panel' do
      fill_in 'percent', with: '75'
      click_button 'provisorisch'
      click_button 'OK'
    end

    page.assert_selector('.planning-calendar .-definitive', count: 3)
    page.assert_selector('.planning-calendar .-provisional', count: 4)
    page.assert_selector('.planning-calendar .-selected', count: 0)
    all('.planning-calendar-week')[0].assert_text('60%')
    all('.planning-calendar-week')[1].assert_text('30%')
    page.assert_selector('.planning-panel', visible: false)
    assert_percents ['50', '50', '50', '75', '75', '75', '75', ''], row
  end

  private

  def assert_percents(percents, row)
    assert_equal percents, row.all('.day')[0..(percents.length - 1)].map(&:text)
  end

  def row_selector
    "#planning_row_employee_#{employees(:mark).id}_work_item_#{work_items(:puzzletime).id}"
  end

  def row
    find(row_selector)
  end

  def list_plannings
    login_as :mark
    visit plannings_employee_path(employees(:mark))
  end
end
