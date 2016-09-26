# encoding: utf-8

require 'test_helper'

class PlanningsOrdersTest < ActionDispatch::IntegrationTest

  setup :list_plannings

  test 'create planning entries' do
    page.assert_selector('.-definitive', count: 2)
    page.assert_selector('.-provisional', count: 0)
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

    page.assert_selector('.-definitive', count: 5)
    page.assert_selector('.-provisional', count: 0)
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
    page.assert_selector('.-definitive', count: 2)
    page.assert_selector('.-provisional', count: 0)
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

    page.assert_selector('.-definitive', count: 0)
    page.assert_selector('.-provisional', count: 2)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    row_mark.all('.day')[0].assert_text('50')
    row_pascal.all('.day')[0].assert_text('25')
  end

  test 'create & update planning entries' do
    page.assert_selector('.-definitive', count: 2)
    page.assert_selector('.-provisional', count: 0)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    row_mark.all('.day')[0].assert_text('50')
    row_pascal.all('.day')[0].assert_text('25')

    drag(row_mark.all('.day')[0], row_pascal.all('.day')[1])

    page.assert_selector('.-selected', count: 4)
    page.assert_selector('.planning-panel', visible: true)

    within '.planning-panel' do
      fill_in 'percent', with: '100'
      click_button 'OK'
    end

    page.assert_selector('.-definitive', count: 4)
    page.assert_selector('.-provisional', count: 0)
    page.assert_selector('.-selected', count: 0)
    page.assert_selector('.planning-panel', visible: false)
    row_mark.all('.day')[0].assert_text('100')
    row_mark.all('.day')[1].assert_text('100')
    row_mark.all('.day')[2].assert_text('')
    row_pascal.all('.day')[0].assert_text('100')
    row_pascal.all('.day')[1].assert_text('100')
    row_pascal.all('.day')[2].assert_text('')
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
