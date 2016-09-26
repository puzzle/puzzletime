require 'test_helper'

module Plannings
  class EmployeesControllerTest < ActionController::TestCase

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
      get :show, id: employees(:lucien).id
      assert_equal accounting_posts(:hitobito_demo_app, :hitobito_demo_site),
                   assigns(:board).accounting_posts
      assert_equal [employees(:lucien)],
                   assigns(:board).employees
    end

  end
end