# encoding: utf-8

require 'test_helper'

class ChooseOrderTest < ActionDispatch::IntegrationTest

  setup :login

  test 'changes path when choosable order changes' do
    timeout_safe do
      selectize('choosable_order_id', 'Demo')

      assert_equal order_path(orders(:hitobito_demo)), current_path
    end
  end

  test 'keeps current tab when changing orders' do
    timeout_safe do
      click_link 'Positionen'
      sleep 0.2
      assert_equal order_accounting_posts_path(order), current_path

      selectize('choosable_order_id', 'Demo')
      assert_equal order_accounting_posts_path(orders(:hitobito_demo)), current_path
      assert page.has_selector?('li.active', text: 'Positionen')
    end
  end

  private

  def order
    @order ||= orders(:puzzletime)
  end

  def login
    login_as(:mark, order_path(order))
  end

end
