# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Plannings
  class OrdersControllerTest < ActionController::TestCase
    setup :login

    test 'GET #new renders row for given employee' do
      get :new,
          xhr: true,
          params: {
            format: :js,
            id: orders(:hitobito_demo).id,
            employee_id: employees(:long_time_john).id,
            work_item_id: work_items(:hitobito_demo_app).id
          }

      assert_equal 200, response.status
      assert_not_empty assigns(:items)
      assert_equal employees(:long_time_john), assigns(:legend)
      assert_includes response.body, 'Neverends John'
    end

    test 'GET#show renders board' do
      date = Time.zone.today.at_beginning_of_week + 1.week
      Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                       employee_id: employees(:pascal).id,
                       date:,
                       percent: 80)
      Planning.create!(work_item_id: work_items(:hitobito_demo_app).id,
                       employee_id: employees(:lucien).id,
                       date:,
                       percent: 60)
      Planning.create!(work_item_id: work_items(:hitobito_demo_site).id,
                       employee_id: employees(:lucien).id,
                       date: date + 1.week,
                       percent: 20)
      get :show, params: { id: orders(:hitobito_demo).id }

      assert_equal accounting_posts(:hitobito_demo_app, :hitobito_demo_site),
                   assigns(:board).accounting_posts
      assert_equal employees(:lucien, :pascal),
                   assigns(:board).employees
    end

    test 'GET#show with start and end date changes period' do
      date = Time.zone.today.at_beginning_of_week
      get :show,
          params: {
            id: orders(:hitobito_demo).id,
            start_date: date + 4.weeks,
            end_date: date + 8.weeks - 1.day
          }

      assert_equal Period.new(date + 4.weeks, date + 8.weeks - 1.day), assigns(:period)
    end

    test 'GET#show with predefined period' do
      get :show,
          params: {
            id: orders(:hitobito_demo).id,
            period_shortcut: '6M'
          }

      assert_operator assigns(:period).length, :>, 180
    end

    test 'GET#show as regular user is allowed' do
      login_as(:pascal)

      get :show, params: { id: orders(:hitobito_demo).id }

      assert_equal 200, response.status
    end

    test 'PATCH update with valid params' do
      patch :update,
            xhr: true,
            params: {
              format: :js,
              id: orders(:puzzletime).id,
              planning: { percent: '50', definitive: 'true' },
              items: { '1' => { employee_id: employees(:pascal).id.to_s,
                                work_item_id: work_items(:puzzletime).id.to_s,
                                date: Time.zone.today.beginning_of_week.strftime('%Y-%m-%d') } }
            }

      assert_equal 200, response.status
      assert_includes response.body, 'Zumkehr Pascal'
      assert_includes response.body, '50'
    end

    test 'PATCH update with invalid params' do
      patch :update,
            xhr: true,
            params: {
              format: :js,
              id: orders(:puzzletime).id,
              planning: {},
              items: { '1' => { employee_id: employees(:pascal).id.to_s,
                                work_item_id: work_items(:puzzletime).id.to_s,
                                date: '2000-01-03' } }
            }

      assert_equal 200, response.status
      assert_includes response.body, 'Bitte füllen Sie das Formular aus'
    end

    test 'PATCH#update as regular user fails' do
      login_as(:pascal)
      assert_raises(CanCan::AccessDenied) do
        patch :update,
              xhr: true,
              params: {
                format: :js,
                id: orders(:puzzletime).id,
                planning: { percent: '50', definitive: 'true' },
                items: { '1' => { employee_id: employees(:pascal).id.to_s,
                                  work_item_id: work_items(:puzzletime).id.to_s,
                                  date: Time.zone.today.beginning_of_week.strftime('%Y-%m-%d') } }
              }
      end
    end

    test 'PATCH#update as order responsible is allowed' do
      orders(:puzzletime).update!(responsible: employees(:pascal))
      login_as(:pascal)

      patch :update,
            xhr: true,
            params: {
              format: :js,
              id: orders(:puzzletime).id,
              planning: { percent: '50', definitive: 'true' },
              items: { '1' => { employee_id: employees(:pascal).id.to_s,
                                work_item_id: work_items(:puzzletime).id.to_s,
                                date: Time.zone.today.beginning_of_week.strftime('%Y-%m-%d') } }
            }

      assert_equal 200, response.status
    end

    test 'PATCH#update on responsible board but for different order does not work' do
      orders(:puzzletime).update!(responsible: employees(:pascal))
      login_as(:pascal)

      assert_no_difference('Planning.count') do
        patch :update,
              xhr: true,
              params: {
                format: :js,
                id: orders(:puzzletime).id,
                planning: { percent: '50', definitive: 'true' },
                items: { '1' => { employee_id: employees(:pascal).id.to_s,
                                  work_item_id: work_items(:webauftritt).id.to_s,
                                  date: Time.zone.today.beginning_of_week.strftime('%Y-%m-%d') } }
              }
      end
    end

    test 'DELETE#destroy deletes given plannings' do
      p = Planning.create!(employee: employees(:mark),
                           work_item: work_items(:puzzletime),
                           date: Time.zone.today.beginning_of_week,
                           percent: 80)
      assert_difference('Planning.count', -1) do
        delete :destroy,
               xhr: true,
               params: {
                 format: :js,
                 id: orders(:puzzletime).id,
                 planning_ids: [p.id]
               }
      end
    end

    test 'DELETE#destroy on responsible board but for different order does not work' do
      p = Planning.create!(employee: employees(:pascal),
                           work_item: work_items(:webauftritt),
                           date: Time.zone.today.beginning_of_week,
                           percent: 80)
      login_as(:lucien)
      assert_no_difference('Planning.count') do
        delete :destroy,
               xhr: true,
               params: {
                 format: :js,
                 id: orders(:hitobito_demo).id,
                 planning_ids: [p.id]
               }
      end
    end
  end
end
