# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class OrderCostsControllerTest < ActionController::TestCase
  setup :login

  test 'GET#show access denied for non-management' do
    login_as :pascal
    assert_raises(CanCan::AccessDenied) do
      get :show, params: { order_id: order.id }
    end
  end

  test 'GET#show sets all expenses' do
    login_as(:mark)
    get :show, params: { order_id: order.id }

    assert_equal 2, assigns(:associated_expenses).count
  end

  test 'GET#show finds all associated meal_compensations' do
    Fabricate(:ordertime,
              employee: employees(:pascal),
              work_item: work_items(:hitobito_demo_app),
              hours: 5,
              meal_compensation: true,
              work_date: 2.weeks.ago)
    Fabricate(:ordertime,
              employee: employees(:mark),
              work_item: work_items(:hitobito_demo_site),
              hours: 2,
              meal_compensation: true,
              work_date: 1.week.ago)

    login_as(:mark)
    get :show, params: { order_id: order.id }

    assert_equal 2, assigns(:associated_meal_compensations).count
  end

  private

  def order
    orders(:hitobito_demo)
  end
end
