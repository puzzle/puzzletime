# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V2
    class GraphitiTest < ActionDispatch::IntegrationTest
      include GraphitiApiHelper

      setup do
        ActionMailer::Base.deliveries.clear
        # pascal (6) and mark (7, management) own the fixture worktimes; lucien (8) is responsible for work item 4
        @pascal = employees(:pascal)
      end

      # ---- authentication and content type ----

      test 'requires authentication' do
        get '/api/v2/departments', headers: JSONAPI

        assert_response :unauthorized
      end

      test 'writes need the json:api content type' do
        login_as(:mark)

        assert_no_difference('Department.count') do
          post '/api/v2/departments', params: payload('departments', name: 'x', shortname: 'xx'),
                                      headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' }
        end
        assert_response :unsupported_media_type
      end

      # ---- simple resource: Department ----

      test 'management creates, updates and deletes a department' do
        login_as(:mark)

        post '/api/v2/departments', params: payload('departments', name: 'New', shortname: 'NW'), headers: JSONAPI

        assert_response :created
        id = json_body.dig('data', 'id')

        patch "/api/v2/departments/#{id}", params: payload('departments', { shortname: 'N2' }, id), headers: JSONAPI

        assert_response :ok
        assert_equal %w[New N2], Department.find(id).slice(:name, :shortname).values

        delete "/api/v2/departments/#{id}", headers: JSONAPI

        assert_response :ok
        assert_not Department.exists?(id)
      end

      test 'validation errors render as json:api errors' do
        login_as(:mark)

        post '/api/v2/departments', params: payload('departments', name: 'New', shortname: 'TOOLONG'),
                                    headers: JSONAPI

        assert_response :unprocessable_content
        assert_equal '/data/attributes/shortname', json_body.dig('errors', 0, 'source', 'pointer')
      end

      test 'filters, sorts, paginates and includes without any extra code' do
        login_as(:mark)
        Employee.where(id: employees(:pascal).id).update_all(department_id: departments(:devtwo).id)

        get '/api/v2/departments', params: { filter: { name: { prefix: 'dev' } }, sort: '-name',
                                             page: { size: 1 }, include: 'employees' }, headers: JSONAPI

        assert_response :ok
        body = json_body

        assert_equal [departments(:devtwo).id.to_s], body['data'].pluck('id')
        assert_equal ['employees'], body['included'].pluck('type').uniq
        assert_includes body['included'].pluck('id'), employees(:pascal).id.to_s

        get '/api/v2/departments', params: { filter: { nope: 1 } }, headers: JSONAPI

        assert_response :bad_request
      end

      test 'regular employees may not write departments' do
        login_as(:pascal)

        assert_no_difference('Department.count') do
          post '/api/v2/departments', params: payload('departments', name: 'x', shortname: 'xx'), headers: JSONAPI
        end
        assert_response :forbidden
      end

      # ---- read-only resource: Employee ----

      test 'employees are read-only and expose only declared attributes' do
        get "/api/v2/employees/#{@pascal.id}", params: { include: 'department' }, headers: JSONAPI.merge(basic_auth)

        assert_response :ok
        assert_equal %w[department_id firstname lastname shortname workplace_id],
                     json_body.dig('data', 'attributes').keys.sort

        assert_raises(ActionController::RoutingError) do
          post '/api/v2/employees', params: payload('employees', firstname: 'x'), headers: JSONAPI.merge(basic_auth)
        end
      end

      # ---- heavy resource: Ordertime ----

      test 'regular user sees only own entries, management all, api client none' do
        login_as(:pascal)

        assert_equal [1, 2, 3], ids('/api/v2/ordertimes')
        assert_equal 404, status_of("/api/v2/ordertimes/#{worktimes(:wt_mw_allgemein).id}")

        login_as(:mark)

        assert_equal Ordertime.order(:id).pluck(:id), ids('/api/v2/ordertimes', page: { size: 100 })

        get '/api/v2/ordertimes', headers: JSONAPI.merge(basic_auth)

        assert_empty json_body['data']
      end

      test 'owner creates with H:MM hours, updates and deletes; employee defaults to the current user' do
        login_as(:pascal)

        post '/api/v2/ordertimes', params: payload('ordertimes', work_item_id: 4, work_date: '2006-12-20',
                                                                 hours: '8:45', description: 'work'),
                                   headers: JSONAPI

        assert_response :created
        entry = Ordertime.find(json_body.dig('data', 'id'))

        assert_equal @pascal, entry.employee
        assert_in_delta 8.75, entry.hours
        assert_in_delta 8.75, json_body.dig('data', 'attributes', 'hours')

        patch "/api/v2/ordertimes/#{entry.id}", params: payload('ordertimes', { hours: '1.5' }, entry.id),
                                                headers: JSONAPI

        assert_response :ok
        assert_in_delta 1.5, entry.reload.hours

        assert_no_emails { delete "/api/v2/ordertimes/#{entry.id}", headers: JSONAPI }
        assert_not Ordertime.exists?(entry.id)
      end

      test 'times are parsed and read back as HH:MM, hours without times clear them' do
        login_as(:pascal)

        post '/api/v2/ordertimes', params: payload('ordertimes', work_item_id: 4, work_date: '2006-12-20',
                                                                 from_start_time: '0800', to_end_time: '12:30'),
                                   headers: JSONAPI

        assert_response :created
        attributes = json_body.dig('data', 'attributes')

        assert_equal %w[08:00 12:30], attributes.values_at('from_start_time', 'to_end_time')
        assert_in_delta 4.5, attributes['hours']

        id = json_body.dig('data', 'id')
        patch "/api/v2/ordertimes/#{id}", params: payload('ordertimes', { hours: '3:00' }, id), headers: JSONAPI

        assert_nil Ordertime.find(id).from_start_time
      end

      test 'employee_id is management only' do
        attrs = { work_item_id: 4, work_date: '2006-12-20', hours: '2' }
        login_as(:pascal)

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes', params: payload('ordertimes', attrs.merge(employee_id: employees(:mark).id)),
                                     headers: JSONAPI
        end
        assert_response :bad_request

        login_as(:mark)
        post '/api/v2/ordertimes', params: payload('ordertimes', attrs.merge(employee_id: @pascal.id)),
                                   headers: JSONAPI

        assert_response :created
        assert_equal @pascal.id, Ordertime.find(json_body.dig('data', 'id')).employee_id
      end

      test 'committed period blocks the employee (Ability) and management booking for themselves (resource check)' do
        @pascal.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        attrs = { work_item_id: 4, work_date: '2006-12-20', hours: '2' }
        login_as(:pascal)

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes', params: payload('ordertimes', attrs), headers: JSONAPI
        end
        assert_response :forbidden

        # a response that comes from a raised exception doesn't commit the (one-shot) test login, so log in again
        login_as(:pascal)
        committed = worktimes(:wt_pz_allgemein)
        patch "/api/v2/ordertimes/#{committed.id}", params: payload('ordertimes', { hours: '5' }, committed.id),
                                                    headers: JSONAPI

        assert_response :forbidden

        login_as(:mark)
        post '/api/v2/ordertimes', params: payload('ordertimes', attrs.merge(employee_id: @pascal.id)),
                                   headers: JSONAPI

        assert_response :created

        employees(:mark).update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        post '/api/v2/ordertimes', params: payload('ordertimes', attrs), headers: JSONAPI

        assert_response :unprocessable_content
        assert_equal '/data/attributes/work_date', json_body.dig('errors', 0, 'source', 'pointer')
      end

      test 'work items without an accounting post are rejected' do
        login_as(:pascal)
        item = WorkItem.where.not(id: AccountingPost.select(:work_item_id)).first

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes', params: payload('ordertimes', work_item_id: item.id, work_date: '2006-12-20',
                                                                   hours: '2'),
                                     headers: JSONAPI
        end
        assert_response :unprocessable_content
        assert_equal '/data/attributes/work_item_id', json_body.dig('errors', 0, 'source', 'pointer')
      end

      test 'deleting another employee\'s entry mails them' do
        login_as(:mark)

        assert_emails 1 do
          delete "/api/v2/ordertimes/#{worktimes(:wt_pz_allgemein).id}", headers: JSONAPI
        end
        assert_equal [@pascal.email], ActionMailer::Base.deliveries.last.to
      end
    end
  end
end
