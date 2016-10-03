require 'test_helper'

module Plannings
  class EmployeesControllerTest < ActionController::TestCase

    setup :login

    test 'GET #new renders row for given work item' do
      xhr :get,
          :new,
          format: :js,
          id: employees(:lucien).id,
          employee_id: employees(:lucien).id,
          work_item_id: work_items(:hitobito_demo_app).id
      assert_equal 200, response.status
      refute_empty assigns(:items)
      assert_equal work_items(:hitobito_demo_app), assigns(:legend)
      assert response.body.include?('PITC-HIT-DEM-APP: App')
    end

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

    test 'GET#show as regular user is allowed' do
      login_as(:pascal)
      get :show, id: employees(:lucien).id
      assert_equal 200, response.status
    end

    test 'PATCH#update as regular user fails' do
      login_as(:pascal)
      assert_raises(CanCan::AccessDenied) do
        patch :update,
              xhr: true,
              format: :js,
              id: employees(:lucien).id,
              planning: { percent: '50', definitive: 'true' },
              items: { '1' => { employee_id: employees(:lucien).id.to_s,
                                work_item_id: work_items(:puzzletime).id.to_s,
                                date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
      end
    end

    test 'PATCH#update for herself is allowed as regular user' do
      login_as(:pascal)
      xhr :patch,
          :update,
          format: :js,
          id: employees(:pascal).id,
          planning: { percent: '50', definitive: 'true' },
          items: { '1' => { employee_id: employees(:pascal).id.to_s,
                            work_item_id: work_items(:puzzletime).id.to_s,
                            date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
      assert_equal 200, response.status
    end

    test 'PATCH#update on own board but for different user does not work' do
      login_as(:pascal)
      assert_no_difference('Planning.count') do
        xhr :patch,
            :update,
            format: :js,
            id: employees(:pascal).id,
            planning: { percent: '50', definitive: 'true' },
            items: { '1' => { employee_id: employees(:lucien).id.to_s,
                              work_item_id: work_items(:puzzletime).id.to_s,
                              date: Date.today.beginning_of_week.strftime('%Y-%m-%d') } }
      end
    end

    test 'DELETE#destroy deletes given plannings' do
      p = Planning.create!(employee: employees(:mark),
                           work_item: work_items(:puzzletime),
                           date: Date.today.beginning_of_week,
                           percent: 80)
      assert_difference('Planning.count', -1) do
        xhr :delete,
            :destroy,
            format: :js,
            id: employees(:mark).id,
            planning_ids: [p.id]
      end
    end

    test 'DELETE#destroy on own board but for different user does not work' do
      p = Planning.create!(employee: employees(:pascal),
                           work_item: work_items(:hitobito_demo),
                           date: Date.today.beginning_of_week,
                           percent: 80)
      login_as(:lucien)
      assert_no_difference('Planning.count') do
        xhr :delete,
            :destroy,
            format: :js,
            id: employees(:lucien).id,
            planning_ids: [p.id]
      end
    end
  end
end
