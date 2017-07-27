#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class OrderUncertaintiesControllerTest < ActionController::TestCase

  test 'GET index as member' do
    login_as :pascal
    get :index, params: { order_id: order.id }
    assert_template :index
    assert_equal 1, assigns(:risks).count
    assert_equal 1, assigns(:chances).count
  end

  test 'GET index as responsible' do
    login_as :lucien
    get :index, params: { order_id: order.id }
    assert_template :index
    assert_equal 1, assigns(:risks).count
    assert_equal 1, assigns(:chances).count
  end

  test 'GET index as management' do
    login_as :mark
    get :index, params: { order_id: order.id }
    assert_template :index
    assert_equal 1, assigns(:risks).count
    assert_equal 1, assigns(:chances).count
  end

  test 'POST create as member' do
    login_as :pascal
    assert_raises(CanCan::AccessDenied) do
      post :create, params: { order_id: order.id, type: 'OrderRisk',
                              order_risk: test_entry_attrs }
    end
  end

  test 'POST create as responsible' do
    login_as :lucien
    assert_difference 'order.order_risks.count' do
      post :create, params: { order_id: order.id, type: 'OrderRisk',
                              order_risk: test_entry_attrs }
      assert 201, response.status
    end
    assert_equal 'Nuclear worst case', OrderRisk.last.name
  end

  test 'POST create as management' do
    login_as :mark
    assert_difference 'order.order_risks.count' do
      post :create, params: { order_id: order.id, type: 'OrderRisk',
                              order_risk: test_entry_attrs }
      assert 201, response.status
    end
    assert_equal 'Nuclear worst case', OrderRisk.last.name
  end

  test 'PATCH update as member' do
    login_as :pascal
    assert_raises(CanCan::AccessDenied) do
      patch :update, params: { order_id: order.id, id: test_entry.id, type: 'OrderRisk',
                               order_risk: { name: 'Nuclear worst case' } }
    end
  end

  test 'PATCH update as responsible' do
    login_as :lucien
    assert_no_changes 'order.order_risks.count' do
      patch :update, params: { order_id: order.id, id: test_entry.id, type: 'OrderRisk',
                               order_risk: { name: 'Nuclear worst case' } }
    end
    assert_equal 'Nuclear worst case', test_entry.reload.name
  end

  test 'PATCH update as management' do
    login_as :mark
    assert_no_changes 'order.order_risks.count' do
      patch :update, params: { order_id: order.id, id: test_entry.id, type: 'OrderRisk',
                               order_risk: { name: 'Nuclear worst case' } }
    end
    assert_equal 'Nuclear worst case', test_entry.reload.name
  end

  test 'DELETE destroy as member' do
    login_as :pascal
    assert_raises(CanCan::AccessDenied) do
      delete :destroy, params: { order_id: order.id, id: test_entry.id, type: 'OrderRisk' }
    end
  end

  test 'DELETE destroy as responsible' do
    login_as :lucien
    assert_difference 'order.order_risks.count', -1 do
      delete :destroy, params: { order_id: order.id, id: test_entry.id, type: 'OrderRisk' }
    end
  end

  test 'DELETE destroy as management' do
    login_as :mark
    assert_difference 'order.order_risks.count', -1 do
      delete :destroy, params: { order_id: order.id, id: test_entry.id, type: 'OrderRisk' }
    end
  end

  private

  def order
    @order ||= test_entry.order
  end

  def test_entry
    @test_entry ||= order_uncertainties(:atomic_desaster)
  end

  def test_entry_attrs
    {
      name: 'Nuclear worst case',
      probability: 'improbable',
      impact: 'high'
    }
  end
end
