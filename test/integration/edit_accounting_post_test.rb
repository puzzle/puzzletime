# encoding: UTF-8

require 'test_helper'

class EditAccountingPostTest < ActionDispatch::IntegrationTest
  fixtures :all
  setup :login

  test "select correct discount radio and input values" do
    choose('discount_fixed')
    fill_in('accounting_post_discount_fixed', with: '1234')
    assert !page.has_selector?('#accounting_post_discount_fixed:disabled')
    assert page.has_selector?('#accounting_post_discount_percent:disabled')

    choose('discount_percent')
    assert page.has_selector?('#accounting_post_discount_fixed:disabled')
    assert !page.has_selector?('#accounting_post_discount_percent:disabled')
    assert_equal "", find_field('accounting_post_discount_fixed', disabled: true).value
    fill_in('accounting_post_discount_percent', with: '1234')

    choose('discount_none')
    assert page.has_selector?('#accounting_post_discount_fixed:disabled')
    assert page.has_selector?('#accounting_post_discount_percent:disabled')
    assert_equal "", find_field('accounting_post_discount_fixed', disabled: true).value
    assert_equal "", find_field('accounting_post_discount_percent', disabled: true).value
  end

  test "calculate correct budget values" do
    must_hours_per_day = WorkingCondition.value_at(Date.today, :must_hours_per_day).to_f

    assert_equal accounting_post.offered_hours, find_field('accounting_post_offered_hours').value.to_f
    assert_equal accounting_post.offered_days, find_field('accounting_post_offered_days').value.to_f
    assert_equal accounting_post.offered_rate, find_field('accounting_post_offered_rate').value.to_f
    assert_equal accounting_post.offered_rate, find_field('accounting_post_offered_rate').value.to_f

    fill_in('accounting_post_offered_hours', with: 200.5)
    fill_in('accounting_post_offered_rate', with: 7.4)
    assert_equal 200.5 / must_hours_per_day, find_field('accounting_post_offered_days').value.to_f
    assert_equal 200.5 * 7.4, find_field('accounting_post_offered_total').value.to_f

    fill_in('accounting_post_offered_days', with: 77)
    assert_equal 77 * must_hours_per_day, find_field('accounting_post_offered_hours').value.to_f
    assert_equal 77 * must_hours_per_day * 7.4, find_field('accounting_post_offered_total').value.to_f

    fill_in('accounting_post_offered_rate', with: 1000)
    assert_equal 77 * must_hours_per_day * 1000, find_field('accounting_post_offered_total').value.to_f

    fill_in('accounting_post_offered_total', with: 1000.01)
    page.find('body').click
    assert_equal "1000", find_field('accounting_post_offered_rate').value
  end

  def accounting_post
    accounting_posts(:puzzletime)
  end

  def login
    login_as(:mark, edit_order_accounting_post_path(accounting_post.order, accounting_post))
  end

end
