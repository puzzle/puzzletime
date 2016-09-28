# encoding: utf-8

require 'test_helper'

module Plannings
  class MultiOrdersControllerTest < ActionController::TestCase

    setup :login

    test 'GET#show renders board' do
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
      get :show, department_id: departments(:devone).id

      assert_equal orders(:puzzletime, :webauftritt),
                   assigns(:boards).collect(&:subject)
    end

    test 'GET new' do
      xhr :get,
          :new,
          format: :js,
          department_id: departments(:devone).id,
          work_item_id: work_items(:puzzletime).id,
          employee_id: employees(:lucien).id

      assert_equal 200, response.status
      assert response.body.include?('Weller Lucien')
    end

    test 'PATCH update' do
      patch :update,
            xhr: true,
            format: :js,
            department_id: departments(:devone).id,
            planning: { percent: '50', definitive: 'true' },
            items: { '1' => { employee_id: employees(:pascal).id.to_s,
                              work_item_id: work_items(:puzzletime).id.to_s,
                              date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
      assert_equal 200, response.status

      assert_equal orders(:puzzletime), assigns(:board).subject
      assert response.body.include?('Zumkehr Pascal')
      assert response.body.include?('50')
    end

    test 'PATCH update as regular user fails' do
      login_as(:lucien)
      assert_raises(CanCan::AccessDenied) do
        patch :update,
              xhr: true,
              format: :js,
              department_id: departments(:devone).id,
              planning: { percent: '50', definitive: 'true' },
              items: { '1' => { employee_id: employees(:lucien).id.to_s,
                                work_item_id: work_items(:webauftritt).id.to_s,
                                date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
      end
    end

    test 'PATCH update as order responsible succeeds' do
      login_as(:lucien)
      patch :update,
            xhr: true,
            format: :js,
            department_id: departments(:devone).id,
            planning: { percent: '50', definitive: 'true' },
            items: { '1' => { employee_id: employees(:pascal).id.to_s,
                              work_item_id: work_items(:hitobito_demo).id.to_s,
                              date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
      assert_equal 200, response.status
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
               department_id: departments(:devone).id,
               planning_ids: [p1.id, p2.id]
      end

      assert_equal 200, response.status
      assert_equal orders(:webauftritt), assigns(:board).subject
    end

  end
end