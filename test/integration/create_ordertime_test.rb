# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class CreateOrdertimeTest < ActionDispatch::IntegrationTest
  setup :login

  test 'create ordertime is successfull' do
    timeout_safe do
      selectize('ordertime_account_id', 'Site', term: 'site')
      fill_in('ordertime_hours', with: 2)
      click_button 'Speichern'

      assert_equal '/ordertimes', current_path
      time = Worktime.order(:id).last

      assert_equal work_items(:hitobito_demo_site), time.account
    end
  end

  test 'create ordertime with validation error keeps account selection' do
    timeout_safe do
      accounting_posts(:hitobito_demo_site).update!(description_required: true)

      selectize('ordertime_account_id', 'Site', term: 'site')
      fill_in('ordertime_hours', with: 2)
      click_button 'Speichern'

      assert page.has_selector?('#error_explanation')
      item = work_items(:hitobito_demo_site)

      assert_equal item.id.to_s, find('#ordertime_account_id', visible: false).value
      element = find('#ordertime_account_id + .selectize-control')

      assert_equal item.label_verbose, element.find('.selectize-input div').text
    end
  end

  test 'create ordertime select accounting_post with billable=true checks billable checkbox' do
    find('#ordertime_billable').set(false)

    assert_not find('#ordertime_billable').checked?
    selectize('ordertime_account_id', 'Webauftritt', term: 'web')

    assert_predicate find('#ordertime_billable'), :checked?
  end

  test 'create ordertime select accounting_post with billable=false unchecks billable checkbox' do
    assert_predicate find('#ordertime_billable'), :checked?
    selectize('ordertime_account_id', 'PuzzleTime', term: 'time')

    assert_not find('#ordertime_billable').checked?
  end

  test 'selecting a accounting_post sets the progress bar to the correct width, corresponding to the remaining budget' do
    selectize('ordertime_account_id', 'PuzzleTime', term: 'time')

    percentage = clipped_used_budget_percentage(accounting_posts(:puzzletime))

    assert_operator (percentage - progressbar_width_in_percent).abs, :<, 0.02

    clear_selectize('ordertime_account_id')

    assert_equal 0, progressbar_width_in_percent
  end

  test 'going over the budget is displayed as 100% width progress bar' do
    Ordertime.create!(employee: employees(:mark),
                      work_date: '2015-08-31',
                      hours: accounting_posts(:puzzletime).offered_hours * 1.5,
                      work_item: work_items(:puzzletime),
                      report_type: 'absolute_day')

    selectize('ordertime_account_id', 'PuzzleTime', term: 'time')

    assert_equal 100, progressbar_width_in_percent
  end

  test 'selecting a accounting_post sets the progress bar to the color green/orange/red, depending on the remaining budget' do
    selectize('ordertime_account_id', 'PuzzleTime', term: 'time')

    percentage = clipped_used_budget_percentage(accounting_posts(:puzzletime))

    assert_equal progressbar_color, expected_color(percentage)
  end

  test 'going over budget sets the colour of the progressbar to red' do
    Ordertime.create!(employee: employees(:mark),
                      work_date: '2015-08-31',
                      hours: accounting_posts(:puzzletime).offered_hours,
                      work_item: work_items(:puzzletime),
                      report_type: 'absolute_day')

    selectize('ordertime_account_id', 'PuzzleTime', term: 'time')

    percentage = clipped_used_budget_percentage(accounting_posts(:puzzletime))

    assert_equal progressbar_color, expected_color(percentage)
  end

  def login
    login_as(:pascal)
    visit(new_ordertime_path)
  end

  # returns the actually used percentage of budget as a float (clipped to 100, if above)
  def clipped_used_budget_percentage(accounting_post)
    offered_hours = accounting_post.offered_hours
    worked_hours = Worktime.where(work_item_id: accounting_post.work_item_id).sum(:hours)

    offered_hours.nil? ? 0 : [(worked_hours * 100) / offered_hours, 100].min
  end

  def expected_color(percentage)
    if percentage < 80
      'green'
    else
      percentage < 100 ? 'orange' : 'red'
    end
  end

  # returns the width of the progressbar in percent as float
  def progressbar_width_in_percent
    find('#live-bar-success')['style'][/width: (\d+)%/, 1].to_f
  end

  def progressbar_color
    find('#live-bar-success')['class'][/bg-([a-z]+)/, 1]
  end
end
