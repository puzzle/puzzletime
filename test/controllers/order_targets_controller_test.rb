require 'test_helper'

class OrderTargetsControllerTest < ActionController::TestCase
  setup :login

  test 'GET show renders targets' do
    get :show, order_id: order.id
    assert_template :show
    assert_equal order_targets(:puzzletime_time, :puzzletime_cost, :puzzletime_quality),
                 assigns(:order_targets)
  end

  test 'GET show as normal user renders targets' do
    login_as(:long_time_john)
    get :show, order_id: order.id
    assert_template :show
    assert_equal 3, assigns(:order_targets).size
  end

  test 'PATCH update updates targets' do
    patch :update,
          order_id: order.id,
          order: {
            "target_#{order_targets(:puzzletime_time).id}" =>
              { rating: 'orange', comment: 'bla bla' },
            "target_#{order_targets(:puzzletime_cost).id}" =>
              { rating: 'green', comment: 'bla bla' },
            "target_#{order_targets(:puzzletime_quality).id}" =>
              { rating: 'red', comment: 'bla bla' } }

    assert_template :show
    assert_equal 'orange', order_targets(:puzzletime_time).reload.rating
    assert_equal 'bla bla', order_targets(:puzzletime_time).reload.comment
    assert_equal 'green', order_targets(:puzzletime_cost).reload.rating
    assert_equal 'red', order_targets(:puzzletime_quality).reload.rating
    assert flash[:notice]
    assert assigns(:errors).blank?
  end

  test 'PATCH update with errors fails' do
    patch :update,
          order_id: order.id,
          order: {
            "target_#{order_targets(:puzzletime_time).id}" =>
              { rating: 'orange', comment: '' },
            "target_#{order_targets(:puzzletime_cost).id}" =>
              { rating: 'green', comment: '' },
            "target_#{order_targets(:puzzletime_quality).id}" =>
              { rating: 'red', comment: 'bla bla' } }

    assert_template :show
    assert assigns(:errors).present?
  end

  test 'PATCH update as normal user fails' do
    login_as(:pascal)
    assert_raises(CanCan::AccessDenied) do
      patch :update, order_id: order.id
    end
  end

  def order
    @order ||= orders(:puzzletime)
  end
end
