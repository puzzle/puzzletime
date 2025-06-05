# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class PlanningsOrdersTest < ActionDispatch::IntegrationTest
  setup :list_plannings

  test 'close panel on cancel' do
    row_mark.all('.day')[0].click

    page.assert_selector('.planning-panel', visible: true)
    within '.planning-panel' do
      click_button 'Abbrechen'
    end

    page.assert_selector('.planning-panel', visible: false)
  end

  test 'close panel on click outside' do
    row_mark.all('.day')[0].click

    page.assert_selector('.planning-panel', visible: true)
    find('.navbar-brand').click

    page.assert_selector('.planning-panel', visible: false)
  end

  test 'close panel on escape' do
    row_mark.all('.day')[0].click

    page.assert_selector('.planning-panel', visible: true)
    find('body').send_keys :escape
    find('body').click

    page.assert_selector('.planning-panel', visible: false)
  end

  test 'form values' do
    date = Time.zone.today.beginning_of_week
    Planning.create!({ employee_id: employees(:pascal).id,
                       work_item_id:,
                       date: (date + 1.day).strftime('%Y-%m-%d'),
                       percent: 25,
                       definitive: true })
    Planning.create!({ employee_id: employees(:pascal).id,
                       work_item_id:,
                       date: (date + 2.days).strftime('%Y-%m-%d'),
                       percent: 25,
                       definitive: false })
    Planning.create!({ employee_id: employees(:pascal).id,
                       work_item_id:,
                       date: (date + 3.days).strftime('%Y-%m-%d'),
                       percent: 40,
                       definitive: false })
    visit plannings_order_path(orders(:puzzletime))

    page.assert_selector('div.-definitive', count: 3)
    page.assert_selector('div.-provisional', count: 2)

    drag(row_pascal.all('.day')[0], row_pascal.all('.day')[1])

    page.assert_selector('#percent:focus')
    assert_equal '25', find('#percent').value
    assert_equal '', find('#percent')['placeholder']
    page.assert_selector('.planning-definitive.active')
    page.assert_selector('.planning-provisional:not(.active)')
    assert_equal 'true', find('#definitive', visible: false).value
    find('.planning-cancel').click

    drag(row_pascal.all('.day')[0], row_pascal.all('.day')[2])

    page.assert_selector('#percent:focus')
    assert_equal '25', find('#percent').value
    assert_equal '', find('#percent')['placeholder']
    page.assert_selector('.planning-definitive:not(.active)')
    page.assert_selector('.planning-provisional:not(.active)')
    assert_equal '', find('#definitive', visible: false).value
    find('.planning-cancel').click

    drag(row_pascal.all('.day')[2], row_pascal.all('.day')[3])

    page.assert_selector('#percent:not(:focus)')
    assert_equal '', find('#percent').value
    assert_equal '?', find('#percent')['placeholder']
    page.assert_selector('.planning-definitive:not(.active)')
    page.assert_selector('.planning-provisional.active')
    assert_equal 'false', find('#definitive', visible: false).value
    find('.planning-cancel').click

    drag(row_pascal.all('.day')[0], row_pascal.all('.day')[4])

    page.assert_selector('#percent:not(:focus)')
    assert_equal '', find('#percent').value
    assert_equal '?', find('#percent')['placeholder']
    page.assert_selector('.planning-definitive:not(.active)')
    page.assert_selector('.planning-provisional:not(.active)')
    assert_equal '', find('#definitive', visible: false).value
  end

  test 'initial board state' do
    page.assert_selector('div.-definitive', count: 2)
    page.assert_selector('div.-provisional', count: 0)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    assert_percents ['50', '', '', '', '', ''], row_mark
    assert_percents ['25', '', '', '', '', ''], row_pascal
  end

  test 'create planning entries' do
    page.assert_selector("#planned_order_#{orders(:puzzletime).id} .total-sum .header-planned-amount",
                         text: '6 / 100')
    drag(row_pascal.all('.day')[2], row_pascal.all('.day')[4])

    page.assert_selector('.-selected', count: 3)
    page.assert_selector('.planning-panel', visible: true)

    within '.planning-panel' do
      fill_in 'percent', with: '100'
      click_button 'OK'
    end

    page.assert_selector('div.-provisional', count: 3)
    page.assert_selector('div.-definitive', count: 2)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    assert_percents ['50', '', '', '', '', ''], row_mark
    assert_percents ['25', '', '100', '100', '100', ''], row_pascal
    page.assert_selector("#planned_order_#{orders(:puzzletime).id} .total-sum .header-planned-amount",
                         text: '30 / 100')
  end

  test 'create planning entries with multiple accounting posts' do
    create_plannings(work_items(:hitobito_demo_app).id)
    create_plannings(work_items(:hitobito_demo_site).id)

    visit plannings_order_path(orders(:hitobito_demo))

    page.assert_selector("#planned_order_#{orders(:hitobito_demo).id} .total-sum .header-planned-amount",
                         text: '16 / 0')
    page.assert_selector("#group_header_times_accounting_post_#{accounting_posts(:hitobito_demo_app).id}",
                         text: '10 / 0 h')
    page.assert_selector("#group_header_times_accounting_post_#{accounting_posts(:hitobito_demo_site).id}",
                         text: '6 / 0 h')

    row = find("#planning_row_employee_#{employees(:pascal).id}_work_item_#{work_items(:hitobito_demo_app).id}")
    drag(row.all('.day')[2], row.all('.day')[4])

    page.assert_selector('.planning-panel', visible: true)

    within '.planning-panel' do
      fill_in 'percent', with: '100'
      click_button 'OK'
    end

    page.assert_selector("#planned_order_#{orders(:hitobito_demo).id} .total-sum .header-planned-amount",
                         text: '40 / 0')
    page.assert_selector("#group_header_times_accounting_post_#{accounting_posts(:hitobito_demo_app).id}",
                         text: '34 / 0 h')
    page.assert_selector("#group_header_times_accounting_post_#{accounting_posts(:hitobito_demo_site).id}",
                         text: '6 / 0 h')
  end

  test 'update planning entries' do
    drag(row_mark.all('.day')[0], row_pascal.all('.day')[0])

    page.assert_selector('.-selected', count: 2)
    page.assert_selector('.planning-panel', visible: true)

    within '.planning-panel' do
      click_button 'provisorisch'
      click_button 'OK'
    end

    page.assert_selector('div.-definitive', count: 0)
    page.assert_selector('div.-provisional', count: 2)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    assert_percents ['50', '', '', '', '', ''], row_mark
    assert_percents ['25', '', '', '', '', ''], row_pascal
  end

  test 'create & update planning entries' do
    drag(row_mark.all('.day')[0], row_pascal.all('.day')[1])

    page.assert_selector('.-selected', count: 4)
    page.assert_selector('.planning-panel', visible: true)

    within '.planning-panel' do
      fill_in 'percent', with: '100'
      click_button 'fix'
      click_button 'OK'
    end

    page.assert_selector('div.-definitive', count: 4)
    page.assert_selector('div.-provisional', count: 0)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    assert_percents ['100', '100', '', '', '', ''], row_mark
    assert_percents ['100', '100', '', '', '', ''], row_pascal
  end

  test 'create repetition' do
    next
    today = Time.zone.today
    today += 1.day if today.saturday?
    today += 1.day if today.sunday?

    page.driver.browser.manage.window.resize_to(1024, 756)
    drag(row_mark.all('.day')[0], row_mark.all('.day')[4])

    page.assert_selector('.-selected', count: 5)
    page.assert_selector('.planning-panel', visible: true)

    within '.planning-panel' do
      page.assert_no_selector('#repeat_until', visible: true)
      check 'repetition'

      page.assert_selector('#repeat_until', visible: true)

      fill_in(
        'repeat_until',
        with: (today + 2.weeks).at_beginning_of_week.strftime('%Y %U')
      )
      # find('#percent').click # required to close calendar popover
      click_button 'OK'
    end

    page.assert_selector('div.-definitive', count: 4)
    page.assert_selector('div.-provisional', count: 0)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)

    percents = ['50', '', '', '', '', '50', '', '', '', '', '50', '', '', '', '', '']

    assert_percents percents, row_mark

    drag(row_mark.all('.day')[0], row_mark.all('.day')[3])

    page.assert_selector('.-selected', count: 4)
    page.assert_selector('.planning-panel', visible: true)

    within '.planning-panel' do
      fill_in 'percent', with: '30'
      click_button 'provisorisch'

      page.assert_no_selector('#repeat_until', visible: true)
      check 'repetition'

      page.assert_selector('#repeat_until', visible: true)

      fill_in 'repeat_until', with: (today + 1.week).strftime('%Y %U')
      # find('#percent').click # required to close calendar popover
      click_button 'OK'
    end

    page.assert_selector('div.-definitive', count: 2)
    page.assert_selector('div.-provisional', count: 8)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)

    percents = ['30', '30', '30', '30', '', '30', '30', '30', '30', '', '50', '', '', '', '', '']

    assert_percents percents, row_mark
  end

  test 'Adding a new employee to the board' do
    page.assert_selector('.add', count: 1)
    page.assert_no_selector('#planning_row_employee_2_work_item_4')

    find('.add').click

    selectize('add_employee_select_id', 'Dolores Pedro', no_click: true)

    page.assert_selector('#planning_row_employee_2_work_item_4', text: 'Dolores Pedro')
    page.assert_selector('#planning_row_employee_2_work_item_4 .day',
                         count: workdays_next_n_months(3))
    page.assert_no_selector('#add_employee_id')
  end

  test 'Select does not show already present employees' do
    assert_includes find('#planning_row_employee_7_work_item_4 .legend').text, 'Waber Mark'
    find('.add').click

    assert_not open_selectize('add_employee_select_id', no_click: true).text.include?('Waber Mark')
  end

  test 'Should not be able to move an empty selection' do
    drag(row_mark.all('.day')[5], row_pascal.all('.day')[9])

    page.assert_selector('.day.-selected', count: 10)
    drag(row_pascal.all('.day')[5], row_pascal.all('.day')[3])

    page.assert_selector('.day.-selected', count: 3)
  end

  test 'Moving planning over exiting planning overwrites the planning' do
    timeout_safe do
      drag(row_mark.all('.day')[5], row_pascal.all('.day')[9])

      within '.planning-panel' do
        fill_in 'percent', with: '100'
        click_button 'fix'
        click_button 'OK'
      end

      within('.planning-calendar') do
        assert_selector('div.-definitive', count: 12)
        drag(row_mark.all('.day')[5], row_pascal.all('.day')[9])

        assert_selector('.day.-selected', count: 10)
        drag(row_pascal.all('.day.-selected')[2], row_mark.all('.day')[0])

        assert_selector('.day.-definitive', count: 10)
      end
    end
  end

  test 'Moving by one cell to the left' do
    drag(row_pascal.all('.day')[1], row_pascal.all('.day')[2])

    within '.planning-panel' do
      fill_in 'percent', with: '100'
      click_button 'fix'
      click_button 'OK'
    end

    page.assert_selector('div.-definitive', count: 4)

    drag(row_pascal.all('.day')[1], row_pascal.all('.day')[2])

    page.assert_selector('.day.-selected', count: 2)
    drag(row_pascal.all('.day.-selected')[1], row_pascal.all('.day')[0])

    row_pascal.assert_selector('.day.-definitive:not(.-selected)', count: 2)
    row_pascal.assert_selector('.day.-definitive:not(.-selected)', count: 2, text: 100)
  end

  test 'Moving by one cell to the right' do
    drag(row_pascal.all('.day')[1], row_pascal.all('.day')[2])

    within '.planning-panel' do
      fill_in 'percent', with: '100'
      click_button 'fix'
      click_button 'OK'
    end

    page.assert_selector('div.-definitive', count: 4)

    drag(row_pascal.all('.day')[1], row_pascal.all('.day')[2])

    page.assert_selector('.day.-selected', count: 2)
    drag(row_pascal.all('.day.-selected')[1], row_pascal.all('.day')[3])

    row_pascal.assert_selector('.day.-definitive:not(.-selected)', count: 3)
    row_pascal.assert_selector('.day.-definitive:not(.-selected)', count: 1, text: 25)
    row_pascal.assert_selector('.day.-definitive:not(.-selected)', count: 2, text: 100)
  end

  test 'Can move selection back to original position' do
    drag(row_pascal.all('.day')[1], row_pascal.all('.day')[2])

    within '.planning-panel' do
      fill_in 'percent', with: '100'
      click_button 'fix'
      click_button 'OK'
    end

    page.assert_selector('div.-definitive', count: 4)
    drag(row_pascal.all('.day')[1], row_pascal.all('.day')[2])

    page.assert_selector('.day.-selected', count: 2)
    drag(
      row_pascal.all('.day')[2],
      row_pascal.all('.day')[8],
      row_pascal.all('.day')[2]
    )

    row_pascal.assert_selector('.day.-definitive', count: 3)
    row_pascal.assert_selector('.day.-definitive.-selected', count: 2)
    row_pascal.assert_selector('.day.-definitive:nth-child(2)', text: 25)
    row_pascal.assert_selector('.day.-definitive:nth-child(3)', text: 100)
    row_pascal.assert_selector('.day.-definitive:nth-child(4)', text: 100)
  end

  test 'delete plannings' do
    row_mark.all('.day')[1].click

    page.assert_selector('.planning-panel', visible: true)
    page.assert_no_selector('.planning-delete', visible: true)
    find('.planning-cancel').click

    page.assert_selector('.planning-panel', visible: false)

    drag(row_mark.all('.day')[0], row_pascal.all('.day')[0])

    page.assert_selector('.planning-panel', visible: true)
    page.assert_selector('.planning-delete', visible: true)
    find('.planning-cancel').click

    page.assert_selector('.planning-panel', visible: false)

    drag(row_mark.all('.day')[0], row_pascal.all('.day')[1])

    page.assert_selector('.planning-panel', visible: true)
    page.assert_selector('.planning-delete', visible: true)

    # assert_difference('Planning.all.to_a.count', -2) do
    accept_confirm('Bist du sicher, dass du die selektierte Planung löschen willst?') do
      find('.planning-delete').click
    end

    page.assert_selector('.planning-panel', visible: false)
    page.assert_selector('div.day.-definitive', count: 0)
    # end

    # FIXME: Why the hell does this work, but Planning.count difference does not?
    assert_equal 1, Planning.all.to_a.size
  end

  test 'switching period' do
    page.assert_selector('#start_date', visible: false)
    page.assert_selector('#end_date', visible: false)
    assert_equal '3M', find('#period_shortcut').value

    select 'Nächste 6 Monate', from: 'period_shortcut'
    find('.navbar-brand').click # blur select

    page.assert_selector('.planning-calendar-weeks',
                         text: "KW #{(Time.zone.today + 6.months - 1.week).cweek}")
    page.assert_selector('#start_date', visible: false)
    page.assert_selector('#end_date', visible: false)
    assert_equal '6M', find('#period_shortcut').value

    drag(row_mark.all('.day')[0], row_pascal.all('.day')[1])

    page.assert_selector('.-selected', count: 4)

    select 'benutzerdefiniert', from: 'period_shortcut'
    find('.navbar-brand').click # blur select

    page.assert_selector('#start_date', visible: true)
    page.assert_selector('#end_date', visible: true)
    assert_equal '', find('#period_shortcut').value

    drag(row_mark.all('.day')[0], row_pascal.all('.day')[2])

    page.assert_selector('.-selected', count: 6)
  end

  test 'period is remembered across planning views' do
    page.assert_selector('.planning-board-header', text: 'PITC-PT: PuzzleTime')
    select 'Nächste 6 Monate', from: 'period_shortcut'
    find('.navbar-brand').click # blur select

    page.assert_selector('.planning-calendar-weeks',
                         text: "KW #{(Time.zone.today + 6.months - 1.week).cweek}")
    page.assert_selector('#start_date', visible: false)
    page.assert_selector('#end_date', visible: false)
    assert_equal '6M', find('#period_shortcut').value

    visit plannings_employee_path(employees(:mark))

    page.assert_selector('.planning-board-header', text: 'Waber Mark')
    page.assert_selector('.planning-calendar-weeks',
                         text: "KW #{(Time.zone.today + 6.months - 1.week).cweek}")
    page.assert_selector('#start_date', visible: false)
    page.assert_selector('#end_date', visible: false)
    assert_equal '6M', find('#period_shortcut').value

    visit plannings_company_path

    page.assert_selector('h1', text: 'Planung aller Members')
    page.assert_selector('#plannings thead',
                         text: (Time.zone.today + 6.months - 1.week).cweek)
    page.assert_selector('#start_date', visible: false)
    page.assert_selector('#end_date', visible: false)
    assert_equal '6M', find('#period_shortcut').value
  end

  test 'add row still works after switching period' do
    find('.add').click

    page.assert_selector('.selectize-dropdown')

    select 'Nächste 6 Monate', from: 'period_shortcut'
    find('.navbar-brand').click # blur select
    select 'Nächste 6 Monate', from: 'period_shortcut' # seems to only update value when selecting 2-times

    page.assert_selector('.planning-calendar-weeks',
                         text: "KW #{(Time.zone.today + 6.months - 1.week).cweek}")
    page.assert_selector('#start_date,#end_date', visible: false)

    page.assert_no_selector('#add_employee_id')
    page.assert_no_selector('.selectize-dropdown')

    find('.add').click

    selectize('add_employee_select_id', 'Dolores Pedro', no_click: true)

    page.assert_selector('#planning_row_employee_2_work_item_4', text: 'Dolores Pedro')
    page.assert_selector('#planning_row_employee_2_work_item_4 .day',
                         count: workdays_next_n_months(6))
    page.assert_no_selector('#add_employee_id')
  end

  test 'collapsable groups' do
    create_plannings(work_items(:hitobito_demo_app).id)

    visit plannings_order_path(orders(:hitobito_demo))

    page.assert_selector('.groupheader', count: 2)
    page.assert_selector('.groupheader.collapsed', count: 1)
    page.assert_selector('.planning-calendar-days', count: 2)

    find('.groupheader:not(.collapsed) .legend').click

    page.assert_selector('.groupheader', count: 2)
    page.assert_selector('.groupheader.collapsed', count: 2)
    page.assert_selector('.planning-calendar-days', count: 0)

    all('.groupheader .legend')[0].click

    page.assert_selector('.groupheader', count: 2)
    page.assert_selector('.groupheader.collapsed', count: 1)
    page.assert_selector('.planning-calendar-days', count: 2)
    page.assert_selector('.selectize-dropdown-content', count: 0)

    all('.groupheader .legend')[1].click

    page.assert_selector('.groupheader', count: 2)
    page.assert_selector('.groupheader.collapsed', count: 0)
    page.assert_selector('.planning-calendar-days', count: 2)
    page.assert_selector('.selectize-dropdown-content', count: 1)
  end

  test 'total time and visible time are shown per row' do
    date = Time.zone.today.beginning_of_week
    Planning.create!({ employee_id: employees(:mark).id,
                       work_item_id:,
                       date: (date + 1.day).strftime('%Y-%m-%d'),
                       percent: 50,
                       definitive: true })
    Planning.create!({ employee_id: employees(:mark).id,
                       work_item_id:,
                       date: (date + 4.months).strftime('%Y-%m-%d'),
                       percent: 50,
                       definitive: true })

    visit plannings_order_path(orders(:puzzletime))

    assert_equal '8 h', row_mark.find('.inperiod-sum').text
    assert_equal '12 h', row_mark.find('.total-sum').text

    select 'Nächste 12 Monate', from: 'period_shortcut'
    sleep 0.5 # give time to update values

    assert_equal '12 h', row_mark.find('.inperiod-sum').text
    assert_equal '12 h', row_mark.find('.total-sum').text
  end

  test 'total overall time for selected period is shown' do
    date = Time.zone.today.beginning_of_week
    Planning.create!({ employee_id: employees(:mark).id,
                       work_item_id:,
                       date: (date + 1.day).strftime('%Y-%m-%d'),
                       percent: 50,
                       definitive: true })
    Planning.create!({ employee_id: employees(:mark).id,
                       work_item_id:,
                       date: (date + 4.months).strftime('%Y-%m-%d'),
                       percent: 50,
                       definitive: true })

    visit plannings_order_path(orders(:puzzletime))

    page.assert_selector("#planned_order_#{orders(:puzzletime).id} .total-sum .header-planned-amount",
                         text: '14 / 100')
    page.assert_selector("#planned_order_#{orders(:puzzletime).id} .inperiod-sum .header-planned-amount",
                         text: '10')

    select 'Nächste 12 Monate', from: 'period_shortcut'
    sleep 0.5 # give time to update values

    page.assert_selector("#planned_order_#{orders(:puzzletime).id} .total-sum .header-planned-amount",
                         text: '14 / 100')
    page.assert_selector("#planned_order_#{orders(:puzzletime).id} .inperiod-sum .header-planned-amount",
                         text: '14')
  end

  private

  def workdays_next_n_months(n, date = Time.zone.today)
    date = date.to_date if date.is_a?(Time)
    date -= (date.wday - 1) % 7
    diff = (date + n.months).end_of_week + 1.week - date.beginning_of_week
    diff.to_i / 7 * 5
  end

  def assert_percents(percents, row)
    assert_equal percents, row.all('.day')[0..(percents.length - 1)].map(&:text)
  end

  def row_mark
    # TODO: without `sleep` I get "Node is either not visible or not an HTMLElement". Why??
    @row_mark ||= find("#planning_row_employee_#{employees(:mark).id}_work_item_#{work_item_id}").tap { sleep 0.1 }
  end

  def row_pascal
    # TODO: without `sleep` I get "Node is either not visible or not an HTMLElement". Why??
    @row_pascal ||= find("#planning_row_employee_#{employees(:pascal).id}_work_item_#{work_item_id}").tap { sleep 0.1 }
  end

  def work_item_id
    work_items(:puzzletime).id
  end

  def create_plannings(work_item_id)
    date = Time.zone.today.beginning_of_week.strftime('%Y-%m-%d')
    Planning.create!({ employee_id: employees(:pascal).id,
                       work_item_id:,
                       date:,
                       percent: 25,
                       definitive: true })
    Planning.create!({ employee_id: employees(:mark).id,
                       work_item_id:,
                       date:,
                       percent: 50,
                       definitive: true })
  end

  def list_plannings
    create_plannings(work_item_id)
    login_as :mark
    visit plannings_order_path(orders(:puzzletime))
    select 'Nächste 3 Monate', from: 'period_shortcut'
  end
end
