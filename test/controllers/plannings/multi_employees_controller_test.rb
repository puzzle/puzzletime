#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Plannings
  class MultiEmployeesControllerTest < ActionController::TestCase
    setup :login

    test 'GET#show renders board' do
      employees(:pascal).employments.create!(percent: 80, start_date: 1.year.ago,
                                             employment_roles_employments: [Fabricate.build(:employment_roles_employment)])
      employees(:lucien).employments.create!(percent: 100, start_date: 5.years.ago,
                                             employment_roles_employments: [Fabricate.build(:employment_roles_employment)])
      employees(:half_year_maria).update!(department: departments(:devtwo))
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

      get :show, params: { department_id: departments(:devtwo).id }

      assert_equal employees(:lucien, :pascal),
                   assigns(:boards).collect(&:subject)
    end

    test 'GET new' do
      get :new,
          xhr: true,
          params: {
            format: :js,
            department_id: departments(:devtwo).id,
            work_item_id: work_items(:puzzletime).id,
            employee_id: employees(:lucien).id
          }

      assert_equal 200, response.status
      assert_includes response.body, 'PuzzleTime', response.body
    end

    test 'PATCH update' do
      patch :update,
            xhr: true,
            params: {
              format: :js,
              department_id: departments(:devtwo).id,
              planning: { percent: '50', definitive: 'true' },
              items: { '1' => { employee_id: employees(:pascal).id.to_s,
                                work_item_id: work_items(:puzzletime).id.to_s,
                                date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
            }

      assert_equal 200, response.status

      assert_equal employees(:pascal), assigns(:board).employee
      assert_includes response.body, 'PuzzleTime', response.body
      assert_includes response.body, '50'
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
                 department_id: departments(:devtwo).id,
                 planning_ids: [p2.id, p4.id]
               }
      end

      assert_equal 200, response.status
      assert_equal employees(:lucien), assigns(:board).subject
    end

    test 'DELETE destroy as regular user fails' do
      p = Planning.create!(employee: employees(:pascal),
                           work_item: work_items(:hitobito_demo),
                           date: Date.today.beginning_of_week,
                           percent: 80)
      login_as(:lucien)
      assert_raises(CanCan::AccessDenied) do
        patch :update,
              xhr: true,
              params: {
                format: :js,
                department_id: departments(:devone).id,
                planning_ids: [p.id]
              }
      end
    end

    test 'DELETE destroy for own plannings succeeds' do
      p = Planning.create!(employee: employees(:pascal),
                           work_item: work_items(:hitobito_demo),
                           date: Date.today.beginning_of_week,
                           percent: 80)
      login_as(:pascal)
      patch :update,
            xhr: true,
            params: {
              format: :js,
              department_id: departments(:devone).id,
              planning_ids: [p.id]
            }

      assert_equal 200, response.status
    end
  end
end
