# encoding: utf-8

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
    keyup('Escape')
    find('body').click
    page.assert_selector('.planning-panel', visible: false)
  end

  test 'form values' do
    date = Date.today.beginning_of_week
    Planning.create!({ employee_id: employees(:pascal).id,
                       work_item_id: work_item_id,
                       date: (date + 1.days).strftime('%Y-%m-%d'),
                       percent: 25,
                       definitive: true })
    Planning.create!({ employee_id: employees(:pascal).id,
                       work_item_id: work_item_id,
                       date: (date + 2.days).strftime('%Y-%m-%d'),
                       percent: 25,
                       definitive: false })
    Planning.create!({ employee_id: employees(:pascal).id,
                       work_item_id: work_item_id,
                       date: (date + 3.days).strftime('%Y-%m-%d'),
                       percent: 40,
                       definitive: false })
    visit plannings_order_path(orders(:puzzletime))
    page.assert_selector('div.-definitive', count: 3)
    page.assert_selector('div.-provisional', count: 2)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)

    drag(row_pascal.all('.day')[0], row_pascal.all('.day')[1])
    page.assert_selector('#percent:focus')
    assert_equal '25', find('#percent').value
    assert_equal '', find('#percent')['placeholder']
    page.assert_selector('.planning-definitive.active')
    page.assert_selector('.planning-provisional:not(.active)')
    assert_equal 'true', find('#definitive', visible: false).value

    drag(row_pascal.all('.day')[0], row_pascal.all('.day')[2])
    page.assert_selector('#percent:focus')
    assert_equal '25', find('#percent').value
    assert_equal '', find('#percent')['placeholder']
    page.assert_selector('.planning-definitive:not(.active)')
    page.assert_selector('.planning-provisional:not(.active)')
    assert_equal '', find('#definitive', visible: false).value

    drag(row_pascal.all('.day')[2], row_pascal.all('.day')[3])
    page.assert_selector('#percent:not(:focus)')
    assert_equal '', find('#percent').value
    assert_equal '?', find('#percent')['placeholder']
    page.assert_selector('.planning-definitive:not(.active)')
    page.assert_selector('.planning-provisional.active')
    assert_equal 'false', find('#definitive', visible: false).value

    drag(row_pascal.all('.day')[0], row_pascal.all('.day')[4])
    page.assert_selector('#percent:not(:focus)')
    assert_equal '', find('#percent').value
    assert_equal '?', find('#percent')['placeholder']
    page.assert_selector('.planning-definitive:not(.active)')
    page.assert_selector('.planning-provisional:not(.active)')
    assert_equal '', find('#definitive', visible: false).value
  end

  test 'create planning entries' do
    page.assert_selector('div.-definitive', count: 2)
    page.assert_selector('div.-provisional', count: 0)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    row_mark.all('.day')[0].assert_text('50')
    row_pascal.all('.day')[0].assert_text('25')

    drag(row_pascal.all('.day')[2], row_pascal.all('.day')[4])

    page.assert_selector('.-selected', count: 3)
    page.assert_selector('.planning-panel', visible: true)

    within '.planning-panel' do
      fill_in 'percent', with: '100'
      click_button 'OK'
    end

    page.assert_selector('div.-definitive', count: 5)
    page.assert_selector('div.-provisional', count: 0)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    row_mark.all('.day')[0].assert_text('50')
    row_pascal.all('.day')[0].assert_text('25')
    row_pascal.all('.day')[2].assert_text('')
    row_pascal.all('.day')[2].assert_text('100')
    row_pascal.all('.day')[3].assert_text('100')
    row_pascal.all('.day')[4].assert_text('100')
  end

  test 'update planning entries' do
    page.assert_selector('div.-definitive', count: 2)
    page.assert_selector('div.-provisional', count: 0)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    row_mark.all('.day')[0].assert_text('50')
    row_pascal.all('.day')[0].assert_text('25')

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
    row_mark.all('.day')[0].assert_text('50')
    row_pascal.all('.day')[0].assert_text('25')
  end

  test 'create & update planning entries' do
    page.assert_selector('div.-definitive', count: 2)
    page.assert_selector('div.-provisional', count: 0)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    row_mark.all('.day')[0].assert_text('50')
    row_pascal.all('.day')[0].assert_text('25')

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
    row_mark.all('.day')[0].assert_text('100')
    row_mark.all('.day')[1].assert_text('100')
    row_mark.all('.day')[2].assert_text('')
    row_pascal.all('.day')[0].assert_text('100')
    row_pascal.all('.day')[1].assert_text('100')
    row_pascal.all('.day')[2].assert_text('')
  end

  test 'Adding a new employee to the board' do
    page.assert_selector('.add', count: 1)
    page.assert_no_selector('#planning_row_employee_2_work_item_4')

    find('.add').click

    selectize('add_employee_select_id', 'Dolores Pedro')
    page.assert_selector('#planning_row_employee_2_work_item_4', text: 'Dolores Pedro')
    page.assert_selector('#planning_row_employee_2_work_item_4 .day', count: 70)
    page.assert_no_selector('#add_employee_id')
  end

  test 'Select does not show already present employees' do
    assert find('#planning_row_employee_7_work_item_4 .legend').text.include?('Waber Mark')
    find('.add').click
    assert_not open_selectize('add_employee_select_id').text.include?('Waber Mark')
  end

  private

  def row_mark
    find("#planning_row_employee_#{employees(:mark).id}_work_item_#{work_item_id}")
  end

  def row_pascal
    find("#planning_row_employee_#{employees(:pascal).id}_work_item_#{work_item_id}")
  end

  def work_item_id
    work_items(:puzzletime).id
  end

  def create_plannings
    date = Date.today.beginning_of_week.strftime('%Y-%m-%d')
    Planning.create!({ employee_id: employees(:pascal).id,
                       work_item_id: work_item_id,
                       date: date,
                       percent: 25,
                       definitive: true })
    Planning.create!({ employee_id: employees(:mark).id,
                       work_item_id: work_item_id,
                       date: date,
                       percent: 50,
                       definitive: true })
  end

  def list_plannings
    create_plannings
    login_as :mark
    visit plannings_order_path(orders(:puzzletime))
  end

end
