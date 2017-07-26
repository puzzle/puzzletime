# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class Employees::WorktimesCommitControllerTest < ActionController::TestCase

  setup :login

  def test_edit_as_manager
    employee = employees(:various_pedro)
    employee.update!(committed_worktimes_at: Date.new(2015, 8, 31))
    get :edit, params: { employee_id: employee.id }
    assert_template '_form'

    selection = assigns(:dates)
    assert_equal selection.size, 13
    assert_equal selection.first.first, Time.zone.today.end_of_month
    assert_equal assigns(:selected_month), Date.new(2015, 9, 30)
  end

  def test_edit_as_regular_user
    login_as(:various_pedro)
    employee = employees(:various_pedro)
    employee.update!(committed_worktimes_at: Date.new(2015, 8, 31))
    get :edit, params: { employee_id: employee.id }
    assert_template '_form'

    selection = assigns(:dates)
    assert_equal selection.size, 2
    assert_equal selection.first.first, (Time.zone.today.end_of_month - 1.month).end_of_month
    assert_equal assigns(:selected_month), Date.new(2015, 9, 30)
  end

  def test_edit_as_new_regular_user
    login_as(:various_pedro)
    employee = employees(:various_pedro)
    employee.update!(committed_worktimes_at: nil)
    get :edit, params: { employee_id: employee.id }
    assert_template '_form'

    selection = assigns(:dates)
    assert_equal selection.size, 2
    assert_equal selection.first.first, (Time.zone.today.end_of_month - 1.month).end_of_month
    assert_nil assigns(:selected_month)
  end

  def test_edit_as_regular_user_is_not_allowed_for_somebody_else
    login_as(:various_pedro)
    assert_raise(CanCan::AccessDenied) do
      get :edit, params: { employee_id: employees(:mark).id }
    end
  end

  def test_update
    employee = employees(:various_pedro)
    employee.update!(committed_worktimes_at: Date.new(2015, 8, 31))
    eom = (Time.zone.today - 1.month).end_of_month
    patch :update,
          params: {
            employee_id: employee.id,
            employee: { committed_worktimes_at: eom }
          }
    assert_equal eom, employee.reload.committed_worktimes_at
  end

  def test_update_is_not_allowed_with_arbitrary_dates
    employee = employees(:various_pedro)
    employee.update!(committed_worktimes_at: Date.new(2015, 8, 31))
    patch :update,
          params: {
            employee_id: employee.id,
            employee: { committed_worktimes_at: Date.new(2015, 10, 15) }
          }
    assert_equal Date.new(2015, 8, 31), employee.reload.committed_worktimes_at
    assert_template '_form'
    assert_match /nicht erlaubt/, assigns(:employee).errors.full_messages.join
  end

end
