#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Plannings
  class MultiOrdersControllerTest < ActionController::TestCase
    setup :login

    test 'GET#show renders board' do
      date = Date.today.at_beginning_of_week + 1.week
      Planning.create!(work_item_id: work_items(:webauftritt).id,
                       employee_id: employees(:pascal).id,
                       date:,
                       percent: 80)
      Planning.create!(work_item_id: work_items(:webauftritt).id,
                       employee_id: employees(:lucien).id,
                       date:,
                       percent: 60)
      Planning.create!(work_item_id: work_items(:puzzletime).id,
                       employee_id: employees(:lucien).id,
                       date: date + 1.week,
                       percent: 20)
      Planning.create!(work_item_id: work_items(:puzzletime).id,
                       employee_id: employees(:lucien).id,
                       date: date + 1.week + 1.day,
                       percent: 20)
      get :show, params: { department_id: departments(:devone).id }

      assert_equal orders(:puzzletime, :webauftritt),
                   assigns(:boards).collect(&:subject)
    end

    test 'GET new' do
      get :new,
          xhr: true,
          params: {
            format: :js,
            department_id: departments(:devone).id,
            work_item_id: work_items(:puzzletime).id,
            employee_id: employees(:lucien).id
          }

      assert_equal 200, response.status
      assert_includes response.body, 'Weller Lucien'
    end

    test 'PATCH update' do
      patch :update,
            xhr: true,
            params: {
              format: :js,
              department_id: departments(:devone).id,
              planning: { percent: '50', definitive: 'true' },
              items: { '1' => { employee_id: employees(:pascal).id.to_s,
                                work_item_id: work_items(:puzzletime).id.to_s,
                                date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
            }

      assert_equal 200, response.status

      assert_equal orders(:puzzletime), assigns(:board).subject
      assert_includes response.body, 'Zumkehr Pascal'
      assert_includes response.body, '50'
    end

    test 'PATCH update as regular user fails' do
      login_as(:lucien)
      assert_raises(CanCan::AccessDenied) do
        patch :update,
              xhr: true,
              params: {
                format: :js,
                department_id: departments(:devone).id,
                planning: { percent: '50', definitive: 'true' },
                items: { '1' => { employee_id: employees(:lucien).id.to_s,
                                  work_item_id: work_items(:webauftritt).id.to_s,
                                  date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
              }
      end
    end

    test 'PATCH update as order responsible succeeds' do
      login_as(:lucien)
      patch :update,
            xhr: true,
            params: {
              format: :js,
              department_id: departments(:devone).id,
              planning: { percent: '50', definitive: 'true' },
              items: { '1' => { employee_id: employees(:pascal).id.to_s,
                                work_item_id: work_items(:hitobito_demo).id.to_s,
                                date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
            }

      assert_equal 200, response.status
    end

    test 'DELETE destroy' do
      date = Date.today.at_beginning_of_week + 1.week
      p1 = Planning.create!(work_item_id: work_items(:webauftritt).id,
                            employee_id: employees(:pascal).id,
                            date:,
                            percent: 80)
      p2 = Planning.create!(work_item_id: work_items(:webauftritt).id,
                            employee_id: employees(:lucien).id,
                            date:,
                            percent: 60)
      p3 = Planning.create!(work_item_id: work_items(:puzzletime).id,
                            employee_id: employees(:lucien).id,
                            date: date + 1.week,
                            percent: 20)
      p4 = Planning.create!(work_item_id: work_items(:puzzletime).id,
                            employee_id: employees(:lucien).id,
                            date: date + 1.week + 1.day,
                            percent: 20)

      assert_difference('Planning.count', -2) do
        delete :destroy,
               xhr: true,
               params: {
                 format: :js,
                 department_id: departments(:devone).id,
                 planning_ids: [p1.id, p2.id]
               }
      end

      assert_equal 200, response.status
      assert_equal orders(:webauftritt), assigns(:board).subject
    end
  end
end
