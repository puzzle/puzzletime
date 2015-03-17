# encoding: UTF-8

require 'test_helper'

class OrderCommentsControllerTest < ActionController::TestCase

  setup :login

  test 'GET index as member redirects and sets flash alert' do
    login_as :pascal
    get :index, order_id: order.id
    assert_response :redirect
    assert_equal 'Sie sind nicht authorisiert, um diese Seite zu öffnen', flash[:alert]
  end

  test 'GET index as responsible renders comments with links' do
    login_as :lucien
    get :index, order_id: order.id
    assert_template :index
    assert_equal order_comments(:puzzletime_first, :puzzletime_second), assigns(:order_comments)
    assert response.body.include?('<a href="http://example.com/dummy">')
  end

  test 'GET index as management renders comments with links' do
    get :index, order_id: order.id
    assert_template :index
    assert_equal order_comments(:puzzletime_first, :puzzletime_second), assigns(:order_comments)
    assert response.body.include?('<a href="http://example.com/dummy">')
  end

  test 'POST index with empty text does not persist comment' do
    assert_no_difference "OrderComment.count" do
      post :create, order_id: order.id, order_comment: {text: ''}
    end
    assert_template :index
  end

  test 'POST index with text persists comment with correct attributes' do
    assert_difference "OrderComment.count", +1 do
      post :create, order_id: order.id, order_comment: {text: 'hello world'}
    end
    assert_match(/wurde erfolgreich erstellt/, flash[:notice])
    comment = assigns(:order_comment)
    assert_equal 'hello world', comment.text
    assert_equal employees(:mark), comment.creator
    assert_equal employees(:mark), comment.updater
  end

  test 'GET show has no configured route' do
    assert_raises ActionController::UrlGenerationError do
      get :show, order_id: order.id
    end
  end

  test 'PATCH update has no configured route' do
    assert_raises ActionController::UrlGenerationError do
      patch :update, order_id: order.id, text: 'blablabla'
    end
  end

  def order
    @order ||= orders(:puzzletime)
  end
end
