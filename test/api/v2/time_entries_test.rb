# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V2
    class TimeEntriesTest < ActionDispatch::IntegrationTest
      JSON_HEADERS = { 'CONTENT_TYPE' => 'application/json' }.freeze

      setup do
        ActionMailer::Base.deliveries.clear
        # pascal (6) and mark (7) own the fixture worktimes; lucien (8) is responsible for work item 4
        @pascal = employees(:pascal)
        @mark = employees(:mark)
      end

      # ---- scope ----

      test 'regular user lists only own entries' do
        login_as(:pascal)

        get '/api/v2/ordertimes'

        assert_response :ok
        assert_equal [1, 2, 3], response.parsed_body.pluck('id')
        assert_equal [4, 13], get_ids('/api/v2/absencetimes')
      end

      test 'management lists everybody\'s entries' do
        login_as(:mark)

        assert_equal Ordertime.order(:id).pluck(:id), get_ids('/api/v2/ordertimes?per_page=100')
        assert_equal Absencetime.order(:id).pluck(:id), get_ids('/api/v2/absencetimes?per_page=100')
      end

      test 'other employees\' entries are 404 for regular users' do
        login_as(:pascal)
        foreign = worktimes(:wt_mw_allgemein)

        get "/api/v2/ordertimes/#{foreign.id}"

        assert_response :not_found

        patch "/api/v2/ordertimes/#{foreign.id}", params: { description: 'x' }.to_json, headers: JSON_HEADERS

        assert_response :not_found

        assert_no_difference('Worktime.count') { delete "/api/v2/ordertimes/#{foreign.id}" }
        assert_response :not_found
        assert_equal 404, status_of(:get, "/api/v2/absencetimes/#{worktimes(:wt_mw_service).id}")
      end

      test 'worktimes of one type are not reachable through the other resource' do
        login_as(:mark)

        assert_equal 404, status_of(:get, "/api/v2/absencetimes/#{worktimes(:wt_mw_allgemein).id}")
        assert_equal 404, status_of(:get, "/api/v2/ordertimes/#{worktimes(:wt_mw_service).id}")
      end

      test 'api client gets nothing' do
        get '/api/v2/ordertimes', headers: basic_auth

        assert_empty response.parsed_body
        get "/api/v2/ordertimes/#{worktimes(:wt_pz_allgemein).id}", headers: basic_auth

        assert_response :not_found

        post '/api/v2/ordertimes/repeat', params: { work_item_id: 4, work_date: '2006-12-04', repetitions: 2 }.to_json,
                                          headers: basic_auth.merge(JSON_HEADERS)

        assert_response :forbidden
      end

      # ---- ordertime CRUD ----

      test 'owner creates, updates and deletes an ordertime' do
        login_as(:pascal)

        post '/api/v2/ordertimes', params: { work_item_id: 4, work_date: '2006-12-20', hours: '8:45',
                                             description: 'work' }.to_json, headers: JSON_HEADERS

        assert_response :created
        body = response.parsed_body
        entry = Ordertime.find(body['id'])

        assert_equal @pascal, entry.employee
        assert_in_delta 8.75, entry.hours
        assert_in_delta 8.75, body['hours']
        assert_equal 6, body['employee_id']
        assert_not body.key?('report_type')

        patch "/api/v2/ordertimes/#{entry.id}", params: { hours: '1.5', description: 'new' }.to_json,
                                                headers: JSON_HEADERS

        assert_response :ok
        assert_equal [1.5, 'new'], entry.reload.slice(:hours, :description).values

        assert_no_emails { delete "/api/v2/ordertimes/#{entry.id}" }
        assert_response :no_content
        assert_not Ordertime.exists?(entry.id)
      end

      test 'times are parsed, hours follow them and hours without times clear them' do
        login_as(:pascal)

        post '/api/v2/ordertimes', params: { work_item_id: 4, work_date: '2006-12-20',
                                             from_start_time: '0800', to_end_time: '12:30' }.to_json,
                                   headers: JSON_HEADERS

        assert_response :created
        entry = Ordertime.find(response.parsed_body['id'])

        assert_in_delta 4.5, entry.hours
        assert_equal '08:00', entry.from_start_time.strftime('%H:%M')

        patch "/api/v2/ordertimes/#{entry.id}", params: { description: 'only text' }.to_json, headers: JSON_HEADERS

        assert_equal '08:00', entry.reload.from_start_time.strftime('%H:%M')

        patch "/api/v2/ordertimes/#{entry.id}", params: { hours: '3:00' }.to_json, headers: JSON_HEADERS

        assert_response :ok
        assert_in_delta 3.0, entry.reload.hours
        assert_nil entry.from_start_time
        assert_nil entry.to_end_time
      end

      test 'empty times are treated as unset' do
        login_as(:pascal)

        post '/api/v2/ordertimes', params: { work_item_id: 4, work_date: '2006-12-20', hours: '2',
                                             from_start_time: '', to_end_time: '' }.to_json, headers: JSON_HEADERS

        assert_response :created
        assert_in_delta 2.0, Ordertime.find(response.parsed_body['id']).hours
      end

      test 'validation errors are 422' do
        login_as(:pascal)

        post '/api/v2/ordertimes', params: { work_date: '2006-12-20', hours: '2' }.to_json, headers: JSON_HEADERS

        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'work_item'
      end

      test 'work item without accounting post is a 422' do
        login_as(:pascal)

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes', params: { work_item_id: 1, work_date: '2006-12-20', hours: '2' }.to_json,
                                     headers: JSON_HEADERS
        end
        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'work_item_id'
      end

      test 'closed work items cannot be booked' do
        login_as(:pascal)
        work_items(:puzzletime).update_column(:closed, true)

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes', params: { work_item_id: 4, work_date: '2006-12-20', hours: '2' }.to_json,
                                     headers: JSON_HEADERS
        end
        assert_response :forbidden
      end

      test 'regular user cannot set employee_id' do
        login_as(:pascal)

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes', params: { work_item_id: 4, work_date: '2006-12-20', hours: '2',
                                               employee_id: @mark.id }.to_json, headers: JSON_HEADERS
        end
        assert_response :forbidden

        patch "/api/v2/ordertimes/#{worktimes(:wt_pz_allgemein).id}", params: { employee_id: @mark.id }.to_json,
                                                                      headers: JSON_HEADERS

        assert_response :forbidden
        assert_equal @pascal.id, worktimes(:wt_pz_allgemein).reload.employee_id
      end

      test 'management books for another employee and edits their entry' do
        login_as(:mark)

        post '/api/v2/ordertimes', params: { work_item_id: 4, work_date: '2006-12-20', hours: '2',
                                             employee_id: @pascal.id }.to_json, headers: JSON_HEADERS

        assert_response :created
        assert_equal @pascal.id, response.parsed_body['employee_id']
        id = response.parsed_body['id']

        patch "/api/v2/ordertimes/#{id}", params: { hours: '4' }.to_json, headers: JSON_HEADERS

        assert_response :ok
        assert_equal @pascal.id, Ordertime.find(id).employee_id
        assert_in_delta 4.0, Ordertime.find(id).hours
      end

      test 'management without employee_id books for self' do
        login_as(:mark)

        post '/api/v2/ordertimes', params: { work_item_id: 4, work_date: '2006-12-20', hours: '2' }.to_json,
                                   headers: JSON_HEADERS

        assert_equal @mark.id, response.parsed_body['employee_id']
      end

      # ---- committed period ----

      test 'committed period blocks the employee but not management' do
        @pascal.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        login_as(:pascal)
        attrs = { work_item_id: 4, work_date: '2006-12-20', hours: '2' }

        assert_no_difference('Ordertime.count') { post '/api/v2/ordertimes', params: attrs.to_json, headers: JSON_HEADERS }
        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'work_date'

        # existing committed rows are neither editable nor deletable
        patch "/api/v2/ordertimes/#{worktimes(:wt_pz_allgemein).id}", params: { hours: '5' }.to_json,
                                                                      headers: JSON_HEADERS

        assert_response :forbidden
        assert_no_difference('Ordertime.count') { delete "/api/v2/ordertimes/#{worktimes(:wt_pz_allgemein).id}" }
        assert_response :forbidden

        # moving an open entry into the committed period is blocked as well
        open_entry = Ordertime.create!(employee: @pascal, work_item_id: 4, work_date: '2007-01-10', hours: 1)
        patch "/api/v2/ordertimes/#{open_entry.id}", params: { work_date: '2006-12-20' }.to_json,
                                                     headers: JSON_HEADERS

        assert_response :unprocessable_content

        login_as(:mark)
        post '/api/v2/ordertimes', params: attrs.merge(employee_id: @pascal.id).to_json, headers: JSON_HEADERS

        assert_response :created
      end

      test 'order responsible may book in own committed period' do
        lucien = employees(:lucien)
        lucien.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        login_as(:lucien)

        post '/api/v2/ordertimes', params: { work_item_id: 4, work_date: '2006-12-20', hours: '2' }.to_json,
                                   headers: JSON_HEADERS

        assert_response :created

        post '/api/v2/ordertimes', params: { work_item_id: 6, work_date: '2006-12-20', hours: '2' }.to_json,
                                   headers: JSON_HEADERS

        assert_response :unprocessable_content
      end

      # ---- delete mail ----

      test 'deleting another employee\'s entries mails them' do
        login_as(:mark)

        assert_emails 1 do
          delete "/api/v2/ordertimes/#{worktimes(:wt_pz_allgemein).id}"
        end
        assert_response :no_content
        assert_equal [@pascal.email], ActionMailer::Base.deliveries.last.to

        assert_emails 1 do
          delete "/api/v2/absencetimes/#{worktimes(:wt_pz_vacation).id}"
        end
        assert_response :no_content
      end

      test 'deleting own entries does not mail' do
        login_as(:mark)

        assert_no_emails { delete "/api/v2/ordertimes/#{worktimes(:wt_mw_allgemein).id}" }
        assert_response :no_content
      end

      # ---- absencetimes ----

      test 'owner manages absencetimes' do
        login_as(:pascal)

        post '/api/v2/absencetimes', params: { absence_id: 1, work_date: '2006-12-20', hours: '8:24',
                                               description: 'sick' }.to_json, headers: JSON_HEADERS

        assert_response :created
        id = response.parsed_body['id']

        assert_in_delta 8.4, response.parsed_body['hours']
        assert_equal [@pascal.id, 1], Absencetime.find(id).slice(:employee_id, :absence_id).values
        assert_not response.parsed_body['billable']

        patch "/api/v2/absencetimes/#{id}", params: { description: 'better' }.to_json, headers: JSON_HEADERS

        assert_response :ok

        delete "/api/v2/absencetimes/#{id}"

        assert_response :no_content
      end

      test 'absence requires an absence' do
        login_as(:pascal)

        post '/api/v2/absencetimes', params: { work_date: '2006-12-20', hours: '8' }.to_json, headers: JSON_HEADERS

        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'absence'
      end

      test 'management cannot update another employee\'s absencetime' do
        login_as(:mark)

        patch "/api/v2/absencetimes/#{worktimes(:wt_pz_vacation).id}", params: { description: 'x' }.to_json,
                                                                       headers: JSON_HEADERS

        assert_response :forbidden
        assert_nil worktimes(:wt_pz_vacation).reload.description
      end

      test 'management creates an absencetime for another employee' do
        login_as(:mark)

        post '/api/v2/absencetimes', params: { absence_id: 1, work_date: '2006-12-20', hours: '8',
                                               employee_id: @pascal.id }.to_json, headers: JSON_HEADERS

        assert_response :created
        assert_equal @pascal.id, response.parsed_body['employee_id']
      end

      test 'regular user cannot book absences for others' do
        login_as(:pascal)

        post '/api/v2/absencetimes', params: { absence_id: 1, work_date: '2006-12-20', hours: '8',
                                               employee_id: @mark.id }.to_json, headers: JSON_HEADERS

        assert_response :forbidden
      end

      test 'committed period blocks absencetimes of the employee' do
        @pascal.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        login_as(:pascal)

        assert_no_difference('Absencetime.count') do
          post '/api/v2/absencetimes', params: { absence_id: 1, work_date: '2006-12-20', hours: '8' }.to_json,
                                       headers: JSON_HEADERS
        end
        assert_response :unprocessable_content
      end

      # ---- multi create ----

      test 'repeat creates one ordertime per employed day' do
        employ(@pascal)
        login_as(:pascal)

        assert_difference('Ordertime.count', 3) do
          post '/api/v2/ordertimes/repeat', params: { work_item_id: 4, work_date: '2006-12-04', repetitions: 3,
                                                      hours: 8.5, description: 'daily' }.to_json,
                                            headers: JSON_HEADERS
        end
        assert_response :created
        assert_equal %w[2006-12-04 2006-12-05 2006-12-06], response.parsed_body.pluck('work_date')
        assert_equal [@pascal.id], Ordertime.where(description: 'daily').pluck(:employee_id).uniq
      end

      test 'repeat is all or nothing' do
        employ(@pascal)
        login_as(:pascal)
        invalid = Ordertime.new.tap { |entry| entry.errors.add(:base, 'boom') }
        AccountingPost.any_instance.stubs(:validate_worktime).returns(nil).then.raises(ActiveRecord::RecordInvalid.new(invalid))

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes/repeat', params: { work_item_id: 4, work_date: '2006-12-04', repetitions: 3,
                                                      hours: 8 }.to_json, headers: JSON_HEADERS
        end
        assert_response :unprocessable_content
        assert_equal ['boom'], response.parsed_body.dig('errors', 'base')
      end

      test 'repeat validates the repetition limit and the committed period' do
        employ(@pascal)
        login_as(:pascal)

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes/repeat', params: { work_item_id: 4, work_date: '2006-12-04', repetitions: 6,
                                                      hours: 8 }.to_json, headers: JSON_HEADERS
        end
        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'repetitions'

        @pascal.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes/repeat', params: { work_item_id: 4, work_date: '2006-12-04', repetitions: 2,
                                                      hours: 8 }.to_json, headers: JSON_HEADERS
        end
        assert_response :unprocessable_content
      end

      test 'repeat for another employee is management only' do
        employ(@pascal)
        body = { work_item_id: 4, work_date: '2006-12-04', repetitions: 2, hours: 8, employee_id: @pascal.id }.to_json
        login_as(:lucien)

        post '/api/v2/ordertimes/repeat', params: body, headers: JSON_HEADERS

        assert_response :forbidden

        login_as(:mark)

        assert_difference('Ordertime.where(employee_id: 6).count', 2) do
          post '/api/v2/ordertimes/repeat', params: body, headers: JSON_HEADERS
        end
        assert_response :created
      end

      test 'multi books absences for the working days of the weeks' do
        employ(@pascal, 50)
        login_as(:pascal)
        start = Date.new(2006, 12, 4)
        expected = (start..(start + 6)).sum { |day| Holiday.musttime(day).positive? ? 1 : 0 }

        assert_difference('Absencetime.count', expected) do
          post '/api/v2/absencetimes/multi', params: { absence_id: 1, work_date: '2006-12-04', duration: 1 }.to_json,
                                             headers: JSON_HEADERS
        end
        assert_response :created
        assert_equal expected, response.parsed_body.size
        assert_equal [@pascal.id], response.parsed_body.pluck('employee_id').uniq
        assert_in_delta Holiday.musttime(start) * 0.5, response.parsed_body.first['hours']
      end

      test 'multi absence validates and is all or nothing' do
        employ(@pascal)
        login_as(:pascal)

        post '/api/v2/absencetimes/multi', params: { absence_id: 1, work_date: '2006-12-04', duration: 0 }.to_json,
                                           headers: JSON_HEADERS

        assert_response :unprocessable_content

        @pascal.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))

        assert_no_difference('Absencetime.count') do
          post '/api/v2/absencetimes/multi', params: { absence_id: 1, work_date: '2006-12-04', duration: 1 }.to_json,
                                             headers: JSON_HEADERS
        end
        assert_response :unprocessable_content
      end

      # ---- commit / review ----

      test 'employee commits own worktimes for the allowed months only' do
        login_as(:pascal)
        last = (Time.zone.today - 1.month).end_of_month

        patch "/api/v2/employees/#{@pascal.id}/worktimes_commit",
              params: { committed_worktimes_at: last.to_s }.to_json, headers: JSON_HEADERS

        assert_response :ok
        assert_equal last, @pascal.reload.committed_worktimes_at
        assert_equal last.to_s, response.parsed_body['committed_worktimes_at']

        [(Time.zone.today - 3.months).end_of_month.to_s, nil, '2020-01-15'].each do |value|
          patch "/api/v2/employees/#{@pascal.id}/worktimes_commit",
                params: { committed_worktimes_at: value }.to_json, headers: JSON_HEADERS

          assert_response :unprocessable_content, value.inspect
          assert_includes response.parsed_body['errors'].keys, 'committed_worktimes_at'
        end
        assert_equal last, @pascal.reload.committed_worktimes_at
      end

      test 'employee cannot commit for others nor review' do
        login_as(:pascal)
        date = Time.zone.today.end_of_month.to_s

        patch "/api/v2/employees/#{@mark.id}/worktimes_commit",
              params: { committed_worktimes_at: date }.to_json, headers: JSON_HEADERS

        assert_response :forbidden

        patch "/api/v2/employees/#{@pascal.id}/worktimes_review",
              params: { reviewed_worktimes_at: date }.to_json, headers: JSON_HEADERS

        assert_response :forbidden
        assert_nil @pascal.reload.reviewed_worktimes_at
      end

      test 'management commits and reviews for anybody within twelve months and may clear' do
        login_as(:mark)
        date = (Time.zone.today - 8.months).end_of_month

        patch "/api/v2/employees/#{@pascal.id}/worktimes_commit",
              params: { committed_worktimes_at: date.to_s }.to_json, headers: JSON_HEADERS

        assert_response :ok
        assert_equal date, @pascal.reload.committed_worktimes_at

        patch "/api/v2/employees/#{@pascal.id}/worktimes_review",
              params: { reviewed_worktimes_at: date.to_s }.to_json, headers: JSON_HEADERS

        assert_response :ok
        assert_equal date, @pascal.reload.reviewed_worktimes_at

        patch "/api/v2/employees/#{@pascal.id}/worktimes_commit",
              params: { committed_worktimes_at: nil }.to_json, headers: JSON_HEADERS

        assert_response :ok
        assert_nil @pascal.reload.committed_worktimes_at

        patch "/api/v2/employees/#{@pascal.id}/worktimes_review",
              params: { reviewed_worktimes_at: (Time.zone.today - 13.months).end_of_month.to_s }.to_json,
              headers: JSON_HEADERS

        assert_response :unprocessable_content
        assert_equal date, @pascal.reload.reviewed_worktimes_at
      end

      test 'commit and review are not reachable through the generic employee routes' do
        login_as(:mark)

        patch "/api/v2/employees/#{@pascal.id}", params: { committed_worktimes_at: '2006-12-31' }.to_json,
                                                 headers: JSON_HEADERS

        assert_not_equal Date.new(2006, 12, 31), @pascal.reload.committed_worktimes_at
      end

      # ---- swagger ----

      test 'swagger documents the time entry routes' do
        login_as(:mark)

        get '/api/v2/swagger_doc'

        assert_response :ok
        spec = response.parsed_body

        assert_includes spec['paths'].keys, '/ordertimes/repeat'
        assert_includes spec['paths'].keys, '/absencetimes/multi'
        assert_includes spec['paths'].keys, '/employees/{id}/worktimes_commit'
        assert_includes spec['paths'].keys, '/employees/{id}/worktimes_review'
        assert_not_includes spec['definitions'].fetch('Ordertime')['properties'].keys, 'report_type'
        assert_not_includes spec['paths'].keys, '/worktimes'
      end

      private

      def employ(employee, percent = 100)
        employment = Employment.new(employee:, percent:, start_date: Date.new(2006, 1, 1))
        employment.employment_roles_employments.build(employment_role: employment_roles(:software_developer),
                                                      employment_role_level: employment_role_levels(:junior),
                                                      percent:)
        employment.save!
      end

      def get_ids(path)
        get path

        response.parsed_body.pluck('id')
      end

      def status_of(verb, path)
        public_send(verb, path)
        response.status
      end

      def basic_auth
        { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(
          Settings.api_client.user, Settings.api_client.password
        ) }
      end
    end
  end
end
