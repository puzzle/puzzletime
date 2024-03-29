# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class OrderControllingControllerTest < ActionController::TestCase
  setup :login

  test 'GET show redirects to login if not authenticated' do
    logout
    get :show, params: { order_id: order.id }

    assert_redirected_to(%r{employees/sign_in})
  end

  test 'GET show returns not found for non-existing order' do
    assert_raises ActiveRecord::RecordNotFound do
      get :show, params: { order_id: 123 }
    end
  end

  test 'GET show assigns controlling data' do
    get :show, params: { order_id: order.id }

    assert_response :success
    assert_kind_of Hash, assigns(:efforts_per_week_cumulated)
    assert_kind_of BigDecimal, assigns(:offered_total)
  end

  private

  def order
    @order ||= orders(:hitobito_demo)
  end
end
