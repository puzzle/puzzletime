# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class CreateAccountingPostTest < ActionDispatch::IntegrationTest
  setup :login

  test 'create / remove accounting post flatrates fields' do
    assert has_no_field?('accounting_post_flatrates_attributes_0_name')
    assert_no_selector('a.remove_nested_fields_link')
    assert_no_selector('.nested_accounting_post_flatrates')

    find('a.add_nested_fields_link').click

    assert has_field?('accounting_post_flatrates_attributes_0_name')
    assert_selector('a.remove_nested_fields_link', count: 1)
    assert_selector('.nested_accounting_post_flatrates', count: 1)

    find('a.remove_nested_fields_link').click

    assert has_no_field?('accounting_post_flatrates_attributes_0_name')
    assert_no_selector('a.remove_nested_fields_link')
    assert_no_selector('.nested_accounting_post_flatrates')

    find('a.add_nested_fields_link').click
    find('a.add_nested_fields_link').click

    assert has_field?('accounting_post_flatrates_attributes_1_name')
    assert_selector('a.remove_nested_fields_link', count: 2)
    assert_selector('.nested_accounting_post_flatrates', count: 2)
  end

  def login
    login_as(:mark)
    visit(new_order_accounting_post_path(order_id: Fabricate(:order).id))
  end
end
