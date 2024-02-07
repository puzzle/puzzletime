# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class MultiEditWorktimes < ActionDispatch::IntegrationTest
  test 'click multi edit link' do
    login_as :mark
    visit order_order_services_path(order_id: orders(:puzzletime))
    find(:css, "#worktime_ids_[value='2']").set(true)
    find(:css, "#worktime_ids_[value='10']").set(true)
    click_link('Auswahl bearbeiten')

    assert page.has_text?('2 Zeiten bearbeiten')
    assert_equal %w[2 10], all('#worktime_ids_', visible: false).map(&:value)
  end
end
