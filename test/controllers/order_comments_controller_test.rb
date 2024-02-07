# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class OrderCommentsControllerTest < ActionController::TestCase
  setup :login

  test 'GET index as member renders with form and comments with links' do
    login_as :pascal
    test_get_and_assert_comments_with_links

    assert_template partial: '_form'
  end

  test 'GET index as responsible renders form and comments with links' do
    login_as :lucien
    test_get_and_assert_comments_with_links

    assert_template partial: '_form'
  end

  test 'GET index as management renders form and comments with links' do
    test_get_and_assert_comments_with_links

    assert_template partial: '_form'
  end

  test 'POST index with empty text does not persist comment' do
    assert_no_difference 'OrderComment.count' do
      post :create, params: { order_id: order.id, order_comment: { text: '' } }
    end
    assert_template :index
  end

  test 'POST index with text persists comment with correct attributes' do
    assert_difference 'OrderComment.count', +1 do
      post :create, params: { order_id: order.id, order_comment: { text: 'hello world' } }
    end
    assert_match(/wurde erfolgreich erstellt/, flash[:notice])
    comment = assigns(:order_comment)

    assert_equal 'hello world', comment.text
    assert_equal employees(:mark), comment.creator
    assert_equal employees(:mark), comment.updater
  end

  test 'GET show has no configured route' do
    assert_raises ActionController::UrlGenerationError do
      get :show, params: { order_id: order.id }
    end
  end

  test 'PATCH update has no configured route' do
    assert_raises ActionController::UrlGenerationError do
      patch :update, params: { order_id: order.id, text: 'blablabla' }
    end
  end

  def order
    @order ||= orders(:puzzletime)
  end

  def test_get_and_assert_comments_with_links
    get :index, params: { order_id: order.id }

    assert_template :index
    assert_equal order_comments(:puzzletime_first, :puzzletime_second), assigns(:order_comments)
    assert_includes response.body, '<a href="http://example.com/dummy">'
  end
end
