# encoding: utf-8

require 'test_helper'

class ChooseOrderTest < ActionDispatch::IntegrationTest
  setup :login

  test 'changes path when choosable order changes' do
    timeout_safe do
      selectize('choosable_order_id', 'Demo', term: 'demo', clear: true)

      assert_equal order_path(orders(:hitobito_demo)), current_path
    end
  end

  test 'changes path when hitting TAB key in order chooser' do
    timeout_safe do      control = find('#choosable_order_id + .selectize-control')
      control.find('.selectize-input').click # open dropdown
      open_selectize('choosable_order_id', term: 'swiss', clear: true)
      find('#choosable_order_id + .selectize-control').find('.selectize-input input').native.send_keys(:tab)

      assert_equal order_path(orders(:webauftritt)), current_path
    end
  end

  test 'keeps current tab when changing orders' do
    timeout_safe do
      click_link 'Positionen'
      assert page.has_selector?('a', text: 'Buchungsposition hinzufügen') # dummy query to wait for page load
      assert_equal order_accounting_posts_path(order), current_path

      selectize('choosable_order_id', 'Demo', term: 'demo', clear: true)
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
