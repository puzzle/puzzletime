#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class EditAccountingPostTest < ActionDispatch::IntegrationTest
  fixtures :all
  setup :login

  test 'calculate correct budget values' do
    WorkingCondition.clear_cache
    must_hours_per_day = WorkingCondition.value_at(Time.zone.today, :must_hours_per_day).to_f

    assert_equal accounting_post.offered_hours, find_field('accounting_post_offered_hours').value.to_f
    assert_equal accounting_post.offered_days, find_field('accounting_post_offered_days').value.to_f
    assert_equal accounting_post.offered_rate, find_field('accounting_post_offered_rate').value.to_f

    fill_in('accounting_post_offered_hours', with: 200.5)
    fill_in('accounting_post_offered_rate', with: 7.4)

    assert_equal 200.5 / must_hours_per_day, find_field('accounting_post_offered_days').value.to_f
    assert_equal 200.5 * 7.4, find_field('accounting_post_offered_total').value.to_f

    page.find('body').click # otherwise capybara will be too fast after the change event
    fill_in('accounting_post_offered_days', with: 77)

    assert_equal 77 * must_hours_per_day, find_field('accounting_post_offered_hours').value.to_f
    assert_in_delta(7.4, find_field('accounting_post_offered_rate').value.to_f)
    assert_equal 77 * must_hours_per_day * 7.4, find_field('accounting_post_offered_total').value.to_f

    page.find('body').click
    fill_in('accounting_post_offered_rate', with: 1000)

    assert_equal 77 * must_hours_per_day, find_field('accounting_post_offered_hours').value.to_f
    assert_equal 77, find_field('accounting_post_offered_days').value.to_f
    assert_equal 77 * must_hours_per_day * 1000, find_field('accounting_post_offered_total').value.to_f

    page.find('body').click
    fill_in('accounting_post_offered_total', with: 1234.01)
    page.find('body').click

    assert_equal '1000', find_field('accounting_post_offered_rate').value
    assert_equal 1234.01 / 1000, find_field('accounting_post_offered_hours').value.to_f
    assert_equal 1234.01 / 1000 / must_hours_per_day, find_field('accounting_post_offered_days').value.to_f

    page.find('body').click
  end

  def accounting_post
    accounting_posts(:puzzletime)
  end

  def login
    login_as(:mark)
    visit(edit_order_accounting_post_path(accounting_post.order, accounting_post))
  end
end
