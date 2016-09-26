require 'test_helper'

module Plannings
  class OrdersControllerTest < ActionController::TestCase

    setup :login

    test 'GET#show renders board' do
      date = Date.today.at_beginning_of_week + 1.week
      Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                       employee_id: employees(:pascal).id,
                       date: date,
                       percent: 80)
      Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                       employee_id: employees(:lucien).id,
                       date: date,
                       percent: 60)
      Planning.create!(work_item_id: work_items(:hitobito_demo_site).id,
                       employee_id: employees(:lucien).id,
                       date: date + 1.weeks,
                       percent: 20)
      get :show, id: orders(:hitobito_demo).id
      assert_equal accounting_posts(:hitobito_demo_app, :hitobito_demo_site),
                   assigns(:accounting_posts)
      assert_equal employees(:lucien, :pascal),
                   assigns(:employees)
    end

    test 'GET#show with start and end date changes period' do
      date = Date.today.at_beginning_of_week
      get :show,
          id: orders(:hitobito_demo).id,
          start_date: date + 4.weeks,
          end_date: date + 8.weeks - 1.day
      assert_equal Period.new(date + 4.weeks, date + 8.weeks - 1.day), assigns(:period)
    end

    test 'GET#show with predefined period' do
      get :show,
          id: orders(:hitobito_demo).id,
          period: '6M'
      assert assigns(:period).length > 180
    end

  end
end