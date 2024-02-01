#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: order_statuses
#
#  id       :integer          not null, primary key
#  name     :string           not null
#  style    :string
#  closed   :boolean          default(FALSE), not null
#  position :integer          not null
#  default  :boolean          default(FALSE), not null
#

require 'test_helper'

class OrderStatusTest < ActiveSupport::TestCase
  test 'closed is propagated to all order work items' do
    status = order_statuses(:bearbeitung)
    status.update!(closed: true)

    assert work_items(:hitobito_demo_app).closed
    assert work_items(:hitobito_demo_site).closed
    assert work_items(:puzzletime).closed
  end

  test 'opened is propagated to all order work items' do
    status = order_statuses(:abgeschlossen)
    status.update!(closed: false)

    assert_not work_items(:allgemein).closed
  end

  test 'defaults scope lists only default statuses' do
    assert_equal OrderStatus.defaults, [order_statuses(:bearbeitung)]
  end
end
