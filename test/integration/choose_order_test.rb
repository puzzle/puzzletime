# encoding: utf-8

require 'test_helper'

class ChosseOrderTest < ActionDispatch::IntegrationTest

  setup :login

  test 'changes path when choosable order changes' do
    save_page

    selectize('choosable_order_id', 'Demo')

    assert_equal order_path(orders(:hitobito_demo)), current_path
  end

  test 'keeps current tab when changing orders' do
    click_link 'Ziele'
    assert_equal targets_order_path(order), current_path

    selectize('choosable_order_id', 'Demo')
    assert_equal targets_order_path(orders(:hitobito_demo)), current_path
    assert page.has_selector?('li.active', text: 'Ziele')
  end

  private

  def order
    @order ||= orders(:puzzletime)
  end

  def login
    login_as(:mark, order_path(order))
  end

end