#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Orders::CommittedControllerTest < ActionController::TestCase
  setup :login

  def test_edit_as_manager
    order = orders(:puzzletime)
    order.update!(committed_at: Date.new(2015, 8, 31))
    get :edit, params: { order_id: order.id }
    assert_template '_form'

    selection = assigns(:dates)
    assert_equal 13, selection.size
    assert_equal Time.zone.today.end_of_month, selection.first.first
  end

  def test_edit_as_responsible_is_not_allowed
    login_as(:lucien)
    order = orders(:puzzletime)
    assert_raise(CanCan::AccessDenied) do
      get :edit, params: { order_id: order.id }
    end
  end

  def test_edit_as_regular_user_is_not_allowed
    login_as(:various_pedro)
    order = orders(:puzzletime)
    assert_raise(CanCan::AccessDenied) do
      get :edit, params: { order_id: order.id }
    end
  end

  def test_update
    order = orders(:puzzletime)
    order.update!(committed_at: Date.new(2015, 8, 31))
    eom = (Time.zone.today - 1.month).end_of_month
    patch :update,
          params: {
            order_id: order.id,
            order: { committed_at: eom }
          }
    assert_equal eom, order.reload.committed_at
  end

  def test_update_is_not_allowed_with_arbitrary_dates
    order = orders(:puzzletime)
    order.update!(committed_at: Date.new(2015, 8, 31))
    patch :update,
          params: {
            order_id: order.id,
            order: { committed_at: Date.new(2015, 10, 15) }
          }
    assert_equal Date.new(2015, 8, 31), order.reload.committed_at
    assert_template '_form'
    assert_match /nicht erlaubt/, assigns(:order).errors.full_messages.join
  end
end
