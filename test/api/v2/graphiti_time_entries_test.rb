# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V2
    # Ordertimes, absencetimes and the worktimes commit/review workflows (the baseline ordertime tests are in
    # GraphitiTest). Scenarios of the Grape time_entries_test.
    class GraphitiTimeEntriesTest < ActionDispatch::IntegrationTest
      include GraphitiApiHelper

      setup do
        ActionMailer::Base.deliveries.clear
        # pascal (6) and mark (7, management) own the fixture worktimes; lucien (8) is responsible for work item 4
        @pascal = employees(:pascal)
        @mark = employees(:mark)
      end

      # ---- scope ----

      test 'regular user lists only own absencetimes, management all' do
        login_as(:pascal)

        assert_equal [4, 13], ids('/api/v2/absencetimes')

        login_as(:mark)

        assert_equal Absencetime.order(:id).pluck(:id), ids('/api/v2/absencetimes', page: { size: 100 })
      end

      test 'other employees\' entries are 404 for regular users' do
        login_as(:pascal)
        foreign = worktimes(:wt_mw_allgemein)

        patch "/api/v2/ordertimes/#{foreign.id}", params: payload('ordertimes', { description: 'x' }, foreign.id),
                                                  headers: JSONAPI

        assert_response :not_found

        login_as(:pascal)
        assert_no_difference('Worktime.count') { delete "/api/v2/ordertimes/#{foreign.id}", headers: JSONAPI }
        assert_response :not_found

        login_as(:pascal)

        assert_equal 404, status_of("/api/v2/absencetimes/#{worktimes(:wt_mw_service).id}")
      end

      test 'worktimes of one type are not reachable through the other resource' do
        login_as(:mark)

        assert_equal 404, status_of("/api/v2/absencetimes/#{worktimes(:wt_mw_allgemein).id}")

        login_as(:mark)

        assert_equal 404, status_of("/api/v2/ordertimes/#{worktimes(:wt_mw_service).id}")
      end

      test 'api client gets nothing and cannot book' do
        get '/api/v2/absencetimes', headers: JSONAPI.merge(basic_auth)

        assert_empty json_body['data']

        post '/api/v2/ordertimes/repeat', params: payload('ordertimes', work_item_id: 4, work_date: '2006-12-04',
                                                                        repetitions: 2),
                                          headers: JSONAPI.merge(basic_auth)

        assert_response :forbidden

        post '/api/v2/absencetimes/multi', params: payload('absencetimes', absence_id: 1, work_date: '2006-12-04',
                                                                           duration: 1),
                                           headers: JSONAPI.merge(basic_auth)

        assert_response :forbidden
      end

      test 'type and internal columns are not exposed' do
        login_as(:pascal)
        get "/api/v2/absencetimes/#{worktimes(:wt_pz_vacation).id}", headers: JSONAPI

        assert_equal %w[absence_id billable description employee_id from_start_time hours to_end_time work_date],
                     json_body.dig('data', 'attributes').keys.sort
        assert_equal 'absencetimes', json_body.dig('data', 'type')
      end

      # ---- ordertime rules beyond the baseline ----

      test 'empty times are treated as unset' do
        login_as(:pascal)

        post '/api/v2/ordertimes', params: payload('ordertimes', work_item_id: 4, work_date: '2006-12-20', hours: '2',
                                                                 from_start_time: '', to_end_time: ''),
                                   headers: JSONAPI

        assert_response :created
        assert_in_delta 2.0, json_body.dig('data', 'attributes', 'hours')
      end

      test 'closed work items cannot be booked' do
        login_as(:pascal)
        work_items(:puzzletime).update_column(:closed, true)

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes', params: payload('ordertimes', work_item_id: 4, work_date: '2006-12-20', hours: '2'),
                                     headers: JSONAPI
        end
        assert_response :forbidden
      end

      test 'regular user cannot move an entry to another employee' do
        login_as(:pascal)

        patch "/api/v2/ordertimes/#{worktimes(:wt_pz_allgemein).id}",
              params: payload('ordertimes', { employee_id: @mark.id }, worktimes(:wt_pz_allgemein).id),
              headers: JSONAPI

        assert_response :bad_request
        assert_equal @pascal.id, worktimes(:wt_pz_allgemein).reload.employee_id
      end

      test 'management books for another employee, edits their entry and defaults to self' do
        login_as(:mark)
        attrs = { work_item_id: 4, work_date: '2006-12-20', hours: '2' }

        post '/api/v2/ordertimes', params: payload('ordertimes', attrs.merge(employee_id: @pascal.id)),
                                   headers: JSONAPI

        assert_response :created
        id = json_body.dig('data', 'id')

        patch "/api/v2/ordertimes/#{id}", params: payload('ordertimes', { hours: '4' }, id), headers: JSONAPI

        assert_response :ok
        assert_equal [@pascal.id, 4.0], Ordertime.find(id).slice(:employee_id, :hours).values

        post '/api/v2/ordertimes', params: payload('ordertimes', attrs), headers: JSONAPI

        assert_equal @mark.id, json_body.dig('data', 'attributes', 'employee_id')
      end

      test 'committed period: existing rows are neither editable nor deletable, moving into it fails' do
        @pascal.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        id = worktimes(:wt_pz_allgemein).id
        login_as(:pascal)

        patch "/api/v2/ordertimes/#{id}", params: payload('ordertimes', { hours: '5' }, id), headers: JSONAPI

        assert_response :forbidden

        login_as(:pascal)
        assert_no_difference('Ordertime.count') { delete "/api/v2/ordertimes/#{id}", headers: JSONAPI }
        assert_response :forbidden

        open_entry = Ordertime.create!(employee: @pascal, work_item_id: 4, work_date: '2007-01-10', hours: 1)
        login_as(:pascal)
        patch "/api/v2/ordertimes/#{open_entry.id}",
              params: payload('ordertimes', { work_date: '2006-12-20' }, open_entry.id), headers: JSONAPI

        # Ability decides on the changed record, before the resource check (Grape: 422)
        assert_response :forbidden
        assert_equal Date.new(2007, 1, 10), open_entry.reload.work_date
      end

      test 'order responsible may book in own committed period, others are blocked' do
        employees(:lucien).update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        login_as(:lucien)

        post '/api/v2/ordertimes', params: payload('ordertimes', work_item_id: 4, work_date: '2006-12-20', hours: '2'),
                                   headers: JSONAPI

        assert_response :created

        post '/api/v2/ordertimes', params: payload('ordertimes', work_item_id: 6, work_date: '2006-12-20', hours: '2'),
                                   headers: JSONAPI

        assert_response :forbidden
      end

      test 'deleting own entries does not mail' do
        login_as(:mark)

        assert_no_emails { delete "/api/v2/ordertimes/#{worktimes(:wt_mw_allgemein).id}", headers: JSONAPI }
        assert_response :ok
      end

      # ---- absencetimes ----

      test 'owner manages absencetimes' do
        login_as(:pascal)

        post '/api/v2/absencetimes', params: payload('absencetimes', absence_id: 1, work_date: '2006-12-20',
                                                                     hours: '8:24', description: 'sick'),
                                     headers: JSONAPI

        assert_response :created
        id = json_body.dig('data', 'id')

        assert_in_delta 8.4, json_body.dig('data', 'attributes', 'hours')
        assert_equal [@pascal.id, 1], Absencetime.find(id).slice(:employee_id, :absence_id).values
        assert_not json_body.dig('data', 'attributes', 'billable')

        patch "/api/v2/absencetimes/#{id}", params: payload('absencetimes', { description: 'better' }, id),
                                            headers: JSONAPI

        assert_response :ok
        assert_equal 'better', Absencetime.find(id).description

        delete "/api/v2/absencetimes/#{id}", headers: JSONAPI

        assert_response :ok
        assert_not Absencetime.exists?(id)
      end

      test 'absence requires an absence and billable is not writable' do
        login_as(:pascal)

        post '/api/v2/absencetimes', params: payload('absencetimes', work_date: '2006-12-20', hours: '8'),
                                     headers: JSONAPI

        assert_response :unprocessable_content
        assert_equal '/data/relationships/absence', json_body.dig('errors', 0, 'source', 'pointer')

        post '/api/v2/absencetimes', params: payload('absencetimes', absence_id: 1, work_date: '2006-12-20',
                                                                     hours: '8', billable: true),
                                     headers: JSONAPI

        assert_response :bad_request
      end

      test 'management cannot update another employee\'s absencetime but books and deletes with mail' do
        login_as(:mark)
        id = worktimes(:wt_pz_vacation).id

        patch "/api/v2/absencetimes/#{id}", params: payload('absencetimes', { description: 'x' }, id), headers: JSONAPI

        assert_response :forbidden
        assert_nil worktimes(:wt_pz_vacation).reload.description

        login_as(:mark)
        post '/api/v2/absencetimes', params: payload('absencetimes', absence_id: 1, work_date: '2006-12-20', hours: '8',
                                                                     employee_id: @pascal.id),
                                     headers: JSONAPI

        assert_response :created
        assert_equal @pascal.id, json_body.dig('data', 'attributes', 'employee_id')

        assert_emails 1 do
          delete "/api/v2/absencetimes/#{id}", headers: JSONAPI
        end
        assert_response :ok
        assert_equal [@pascal.email], ActionMailer::Base.deliveries.last.to
      end

      test 'regular user cannot book absences for others' do
        login_as(:pascal)

        post '/api/v2/absencetimes', params: payload('absencetimes', absence_id: 1, work_date: '2006-12-20', hours: '8',
                                                                     employee_id: @mark.id),
                                     headers: JSONAPI

        assert_response :bad_request
      end

      test 'committed period blocks absencetimes of the employee' do
        @pascal.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        login_as(:pascal)

        assert_no_difference('Absencetime.count') do
          post '/api/v2/absencetimes', params: payload('absencetimes', absence_id: 1, work_date: '2006-12-20',
                                                                       hours: '8'),
                                       headers: JSONAPI
        end
        assert_response :forbidden
      end

      test 'management booking an absence for themselves in their committed period hits the resource check' do
        @mark.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        login_as(:mark)

        assert_no_difference('Absencetime.count') do
          post '/api/v2/absencetimes', params: payload('absencetimes', absence_id: 1, work_date: '2006-12-20',
                                                                       hours: '8'),
                                       headers: JSONAPI
        end
        assert_response :unprocessable_content
        assert_equal '/data/attributes/work_date', json_body.dig('errors', 0, 'source', 'pointer')
      end

      # ---- multi create ----

      test 'repeat creates one ordertime per employed day' do
        employ(@pascal)
        login_as(:pascal)

        assert_difference('Ordertime.count', 3) do
          post '/api/v2/ordertimes/repeat',
               params: payload('ordertimes', work_item_id: 4, work_date: '2006-12-04', repetitions: 3, hours: 8.5,
                                             description: 'daily'),
               headers: JSONAPI
        end
        assert_response :created
        assert_equal(%w[2006-12-04 2006-12-05 2006-12-06], json_body['data'].map { |e| e.dig('attributes', 'work_date') })
        assert_equal [@pascal.id], Ordertime.where(description: 'daily').pluck(:employee_id).uniq
      end

      test 'repeat is all or nothing' do
        employ(@pascal)
        login_as(:pascal)
        AccountingPost.any_instance.stubs(:validate_worktime).with do |entry|
          entry.errors.add(:base, 'boom') if entry.work_date == Date.new(2006, 12, 5)
          true
        end

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes/repeat', params: payload('ordertimes', work_item_id: 4, work_date: '2006-12-04',
                                                                          repetitions: 3, hours: 8),
                                            headers: JSONAPI
        end
        assert_response :unprocessable_content
        assert_equal 'boom', json_body.dig('errors', 0, 'detail')
      end

      test 'repeat validates the repetition limit and the committed period' do
        employ(@pascal)
        login_as(:pascal)

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes/repeat', params: payload('ordertimes', work_item_id: 4, work_date: '2006-12-04',
                                                                          repetitions: 6, hours: 8),
                                            headers: JSONAPI
        end
        assert_response :unprocessable_content
        assert_equal '/data/attributes/repetitions', json_body.dig('errors', 0, 'source', 'pointer')

        @pascal.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        login_as(:pascal)

        assert_no_difference('Ordertime.count') do
          post '/api/v2/ordertimes/repeat', params: payload('ordertimes', work_item_id: 4, work_date: '2006-12-04',
                                                                          repetitions: 2, hours: 8),
                                            headers: JSONAPI
        end
        assert_response :forbidden
      end

      test 'repeat for another employee is management only' do
        employ(@pascal)
        body = payload('ordertimes', work_item_id: 4, work_date: '2006-12-04', repetitions: 2, hours: 8,
                                     employee_id: @pascal.id)
        login_as(:lucien)

        post '/api/v2/ordertimes/repeat', params: body, headers: JSONAPI

        assert_response :forbidden

        login_as(:mark)

        assert_difference('Ordertime.where(employee_id: 6).count', 2) do
          post '/api/v2/ordertimes/repeat', params: body, headers: JSONAPI
        end
        assert_response :created
      end

      test 'multi books absences for the working days of the weeks' do
        employ(@pascal, 50)
        login_as(:pascal)
        start = Date.new(2006, 12, 4)
        expected = (start..(start + 6)).sum { |day| Holiday.musttime(day).positive? ? 1 : 0 }

        assert_difference('Absencetime.count', expected) do
          post '/api/v2/absencetimes/multi', params: payload('absencetimes', absence_id: 1, work_date: '2006-12-04',
                                                                             duration: 1),
                                             headers: JSONAPI
        end
        assert_response :created
        assert_equal expected, json_body['data'].size
        assert_equal [@pascal.id], json_body['data'].map { |e| e.dig('attributes', 'employee_id') }.uniq
        assert_in_delta Holiday.musttime(start) * 0.5, json_body.dig('data', 0, 'attributes', 'hours')
      end

      test 'multi absence validates and is all or nothing' do
        employ(@pascal)
        login_as(:pascal)

        post '/api/v2/absencetimes/multi', params: payload('absencetimes', absence_id: 1, work_date: '2006-12-04',
                                                                           duration: 0),
                                           headers: JSONAPI

        assert_response :unprocessable_content

        @pascal.update_column(:committed_worktimes_at, Date.new(2006, 12, 31))
        login_as(:pascal)

        assert_no_difference('Absencetime.count') do
          post '/api/v2/absencetimes/multi', params: payload('absencetimes', absence_id: 1, work_date: '2006-12-04',
                                                                             duration: 1),
                                             headers: JSONAPI
        end
        assert_response :forbidden
      end

      # ---- commit / review ----

      test 'employee commits own worktimes for the allowed months only' do
        login_as(:pascal)
        last = (Time.zone.today - 1.month).end_of_month

        commit(@pascal, last.to_s)

        assert_response :ok
        assert_equal last, @pascal.reload.committed_worktimes_at
        assert_equal last.to_s, json_body.dig('data', 'attributes', 'committed_worktimes_at')

        [(Time.zone.today - 3.months).end_of_month.to_s, nil, '2020-01-15', 'garbage'].each do |value|
          login_as(:pascal)
          commit(@pascal, value)

          assert_response :unprocessable_content, value.inspect
          assert_equal '/data/attributes/committed_worktimes_at', json_body.dig('errors', 0, 'source', 'pointer')
        end
        assert_equal last, @pascal.reload.committed_worktimes_at
      end

      test 'employee cannot commit for others nor review' do
        login_as(:pascal)
        date = Time.zone.today.end_of_month.to_s

        commit(@mark, date)

        assert_response :forbidden

        login_as(:pascal)
        patch "/api/v2/employees/#{@pascal.id}/worktimes_review",
              params: payload('employees', reviewed_worktimes_at: date), headers: JSONAPI

        assert_response :forbidden
        assert_nil @pascal.reload.reviewed_worktimes_at
      end

      test 'management commits and reviews for anybody within twelve months and may clear' do
        login_as(:mark)
        date = (Time.zone.today - 8.months).end_of_month

        commit(@pascal, date.to_s)

        assert_response :ok
        assert_equal date, @pascal.reload.committed_worktimes_at

        patch "/api/v2/employees/#{@pascal.id}/worktimes_review",
              params: payload('employees', reviewed_worktimes_at: date.to_s), headers: JSONAPI

        assert_response :ok
        assert_equal date, @pascal.reload.reviewed_worktimes_at

        commit(@pascal, nil)

        assert_response :ok
        assert_nil @pascal.reload.committed_worktimes_at

        patch "/api/v2/employees/#{@pascal.id}/worktimes_review",
              params: payload('employees', reviewed_worktimes_at: (Time.zone.today - 13.months).end_of_month.to_s),
              headers: JSONAPI

        assert_response :unprocessable_content
        assert_equal date, @pascal.reload.reviewed_worktimes_at
      end

      test 'api client cannot commit' do
        patch "/api/v2/employees/#{@pascal.id}/worktimes_commit",
              params: payload('employees', committed_worktimes_at: Time.zone.today.end_of_month.to_s),
              headers: JSONAPI.merge(basic_auth)

        assert_response :forbidden
      end

      private

      def commit(employee, value)
        patch "/api/v2/employees/#{employee.id}/worktimes_commit",
              params: payload('employees', committed_worktimes_at: value), headers: JSONAPI
      end

      def employ(employee, percent = 100)
        employment = Employment.new(employee:, percent:, start_date: Date.new(2006, 1, 1))
        employment.employment_roles_employments.build(employment_role: employment_roles(:software_developer),
                                                      employment_role_level: employment_role_levels(:junior),
                                                      percent:)
        employment.save!
      end
    end
  end
end
