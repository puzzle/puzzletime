#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

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
    timeout_safe do
      control = find('#choosable_order_id + .selectize-control')
      control.find('.selectize-input').click # open dropdown
      open_selectize('choosable_order_id', term: 'swiss', clear: true)
      find('#choosable_order_id + .selectize-control').find('.selectize-input input').native.send_keys(:tab)

      assert page.has_selector?('dd.value', text: 'Webauftritt') # dummy query to wait for page load
      assert_equal order_path(orders(:webauftritt)), current_path
    end
  end

  test 'keeps current tab when changing orders' do
    timeout_safe do
      click_link 'Positionen'
      assert page.has_link?(href: new_order_accounting_post_path(order_id: order.id)) # query forces to wait for page load
      assert_equal order_accounting_posts_path(order), current_path

      selectize('choosable_order_id', 'Demo', term: 'demo', clear: true)
      assert page.has_link?(href: new_order_accounting_post_path(order_id: orders(:hitobito_demo).id)) # query forces to wait for page load
      assert_equal order_accounting_posts_path(orders(:hitobito_demo)), current_path
      assert page.has_selector?('li.active', text: 'Positionen')
    end
  end

  private

  def order
    @order ||= orders(:puzzletime)
  end

  def login
    login_as(:mark)
    visit(order_path(order))
  end
end
