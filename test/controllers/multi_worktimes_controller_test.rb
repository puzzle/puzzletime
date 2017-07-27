#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class MultiWorktimesControllerTest < ActionController::TestCase
  setup :login

  test 'GET edit without worktimes fails' do
    get :edit, params: { order_id: order.id }
    assert_redirected_to order_order_services_path(order, returning: true)
    assert flash[:alert].present?
  end

  test 'GET edit loads worktimes' do
    get :edit,
        params: {
          order_id: order.id,
          worktime_ids: worktimes(:wt_mw_puzzletime, :wt_pz_puzzletime).collect(&:id)
        }
    assert_template 'edit'
    assert_equal 2, assigns(:worktimes).size
  end

  test 'GET edit loads worktimes of non-management' do
    login_as(:pascal)
    get :edit,
        params: {
          order_id: order.id,
          worktime_ids: [worktimes(:wt_pz_puzzletime).id]
        }
    assert_template 'edit'
    assert_equal 1, assigns(:worktimes).size
  end

  test 'GET edit validates own worktimes' do
    login_as(:pascal)

    assert_raise(CanCan::AccessDenied) do
      get :edit,
          params: {
            order_id: order.id,
            worktime_ids: [worktimes(:wt_mw_puzzletime).id]
          }
    end

    assert_raise(CanCan::AccessDenied) do
      get :edit,
          params: {
            order_id: order.id,
            worktime_ids: worktimes(:wt_mw_puzzletime, :wt_pz_puzzletime).collect(&:id)
          }
    end
  end

  test 'GET edit presets work_item if all are equal' do
    get :edit,
        params: {
          order_id: order.id,
          worktime_ids: worktimes(:wt_mw_puzzletime, :wt_pz_puzzletime).collect(&:id)
        }
    assert_equal work_items(:puzzletime), assigns(:work_item)
    assert_equal true, assigns(:billable)
    assert_nil assigns(:ticket)
  end

  test 'GET edit presets ticket if all are equal' do
    get :edit,
        params: {
          order_id: order.id,
          worktime_ids: worktimes(:wt_pz_webauftritt, :wt_pz_puzzletime).collect(&:id)
        }
    assert_nil assigns(:work_item)
    assert_nil assigns(:billable)
    assert_equal 'rc1', assigns(:ticket)
  end

  test 'PATCH update updates all worktimes' do
    patch :update,
          params: {
            order_id: order.id,
            worktime_ids: worktimes(:wt_mw_puzzletime, :wt_pz_puzzletime).collect(&:id),
            change_ticket: true,
            ticket: 'rc2',
            change_billable: true,
            billable: false,
            work_item_id: 123
          }
    assert_redirected_to(order_order_services_path(order, returning: true))
    assert_match(/2 Zeiten/, flash[:notice])

    t1 = worktimes(:wt_mw_puzzletime).reload
    t2 = worktimes(:wt_pz_puzzletime).reload
    assert_equal 'rc2', t1.ticket
    assert_equal false, t1.billable
    assert_equal work_items(:puzzletime).id, t1.work_item_id
    assert_equal 'rc2', t2.ticket
    assert_equal false, t2.billable
    assert_equal work_items(:puzzletime).id, t2.work_item_id
  end

  test 'PATCH update without change checks does nothing' do
    patch :update,
          params: {
            order_id: order.id,
            worktime_ids: worktimes(:wt_mw_puzzletime, :wt_pz_puzzletime).collect(&:id),
            change_ticket: false,
            ticket: 'rc2',
            change_billable: false,
            billable: false,
            work_item_id: 123
          }
    assert_redirected_to(order_order_services_path(order, returning: true))
    assert_match(/keine Änderungen/, flash[:notice])

    t1 = worktimes(:wt_mw_puzzletime).reload
    assert_nil t1.ticket
    assert_equal true, t1.billable
    assert_equal work_items(:puzzletime).id, t1.work_item_id
  end

  test 'PATCH update with validation errors does nothing' do
    accounting_posts(:webauftritt).update!(ticket_required: true)
    patch :update,
          params: {
            order_id: order.id,
            worktime_ids: worktimes(:wt_pz_puzzletime, :wt_pz_webauftritt).collect(&:id),
            change_ticket: true,
            ticket: '',
            change_billable: true,
            billable: false
          }

    assert_template 'edit'
    assert assigns(:errors).present?

    t1 = worktimes(:wt_pz_puzzletime).reload
    assert_equal 'rc1', t1.ticket
    assert_equal true, t1.billable
  end

  test 'PATCH update with foreign worktime is now allowed' do
    login_as(:pascal)

    assert_raise(CanCan::AccessDenied) do
      patch :update,
            params: {
              order_id: order.id,
              worktime_ids: [worktimes(:wt_mw_puzzletime).id],
              change_ticket: true,
              ticket: '',
              change_billable: true,
              billable: false
            }
    end

    assert_raise(CanCan::AccessDenied) do
      patch :update,
            params: {
              order_id: order.id,
              worktime_ids: worktimes(:wt_mw_puzzletime, :wt_pz_webauftritt).collect(&:id),
              change_ticket: true,
              ticket: '',
              change_billable: true,
              billable: false
            }
    end
  end

  private

  def order
    orders(:puzzletime)
  end
end
