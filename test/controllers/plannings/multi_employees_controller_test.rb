# encoding: utf-8

require 'test_helper'

module Plannings
  class MultiEmployeesControllerTest < ActionController::TestCase

    setup :login

    test 'GET#show renders board' do
      employees(:pascal).employments.create!(percent: 80, start_date: 1.year.ago)
      employees(:lucien).employments.create!(percent: 100, start_date: 5.years.ago)
      employees(:half_year_maria).update!(department: departments(:devtwo))
      date = Date.today.at_beginning_of_week + 1.week
      Planning.create!(work_item_id: work_items(:webauftritt).id,
                       employee_id: employees(:pascal).id,
                       date: date,
                       percent: 80)
      Planning.create!(work_item_id: work_items(:webauftritt).id,
                       employee_id: employees(:lucien).id,
                       date: date,
                       percent: 60)
      Planning.create!(work_item_id: work_items(:puzzletime).id,
                       employee_id: employees(:lucien).id,
                       date: date + 1.weeks,
                       percent: 20)
      Planning.create!(work_item_id: work_items(:puzzletime).id,
                       employee_id: employees(:lucien).id,
                       date: date + 1.weeks + 1.day,
                       percent: 20)

      get :show, department_id: departments(:devtwo).id

      assert_equal employees(:lucien, :pascal),
                   assigns(:boards).collect(&:subject)
    end

    test 'GET new' do
      xhr :get,
          :new,
          format: :js,
          department_id: departments(:devtwo).id,
          work_item_id: work_items(:puzzletime).id,
          employee_id: employees(:lucien).id

      assert_equal 200, response.status
      assert response.body.include?('PuzzleTime'), response.body
    end

    test 'PATCH update' do
      patch :update,
            xhr: true,
            format: :js,
            department_id: departments(:devtwo).id,
            planning: { percent: '50', definitive: 'true' },
            items: { '1' => { employee_id: employees(:pascal).id.to_s,
                              work_item_id: work_items(:puzzletime).id.to_s,
                              date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
      assert_equal 200, response.status

      assert_equal employees(:pascal), assigns(:board).employee
      assert response.body.include?('PuzzleTime'), response.body
      assert response.body.include?('50')
    end

    test 'DELETE destroy' do
      date = Date.today.at_beginning_of_week + 1.week
      p1 = Planning.create!(work_item_id: work_items(:webauftritt).id,
                       employee_id: employees(:pascal).id,
                       date: date,
                       percent: 80)
      p2 = Planning.create!(work_item_id: work_items(:webauftritt).id,
                       employee_id: employees(:lucien).id,
                       date: date,
                       percent: 60)
      p3 = Planning.create!(work_item_id: work_items(:puzzletime).id,
                       employee_id: employees(:lucien).id,
                       date: date + 1.weeks,
                       percent: 20)
      p4 = Planning.create!(work_item_id: work_items(:puzzletime).id,
                       employee_id: employees(:lucien).id,
                       date: date + 1.weeks + 1.day,
                       percent: 20)

      assert_difference('Planning.count', -2) do
        delete :destroy,
               xhr: true,
               format: :js,
               department_id: departments(:devtwo).id,
               planning_ids: [p2.id, p4.id]
      end

      assert_equal 200, response.status
      assert_equal employees(:lucien), assigns(:board).subject
    end

  end
end