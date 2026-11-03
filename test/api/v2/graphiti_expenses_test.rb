# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V2
    # Expenses (CRUD, receipt, review), overtime vacations and employments (with their roles as nested attributes); the
    # scenarios of the Grape expenses tests.
    class GraphitiExpensesTest < ActionDispatch::IntegrationTest
      include GraphitiApiHelper

      PNG = Rails.root.join('test/fixtures/files/lorem-ipsum.png')

      # --- expenses: scope isolation

      test 'employee lists and shows only own expenses' do
        login_as(:pascal)

        assert_equal Expense.where(employee_id: employees(:pascal).id).pluck(:id).sort, ids('/api/v2/expenses').sort

        other = create_expense(:lucien)
        login_as(:pascal)

        assert_equal 404, status_of("/api/v2/expenses/#{other.id}")
      end

      test 'management sees all expenses and can filter by status' do
        login_as(:mark)

        assert_equal Expense.pluck(:id).sort, ids('/api/v2/expenses', page: { size: 100 }).sort

        login_as(:mark)

        assert_equal Expense.approved.pluck(:id).sort, ids('/api/v2/expenses', filter: { status: 'approved' }).sort
      end

      test 'employee cannot update or delete foreign expenses' do
        other = create_expense(:lucien)
        login_as(:pascal)

        patch "/api/v2/expenses/#{other.id}", params: payload('expenses', { description: 'hack' }, other.id),
                                              headers: JSONAPI

        assert_response :not_found

        login_as(:pascal)
        delete "/api/v2/expenses/#{other.id}", headers: JSONAPI

        assert_response :not_found
        assert Expense.exists?(other.id)
      end

      test 'employee expenses are filtered by employee_id and scoped' do
        create_expense(:lucien)
        login_as(:pascal)

        assert_empty ids('/api/v2/expenses', filter: { employee_id: employees(:lucien).id })
        assert_equal Expense.where(employee_id: employees(:pascal).id).count,
                     ids('/api/v2/expenses', filter: { employee_id: employees(:pascal).id }).size
      end

      test 'api client sees no expenses and cannot write' do
        get '/api/v2/expenses', headers: JSONAPI.merge(basic_auth)

        assert_response :ok
        assert_empty json_body['data']

        post '/api/v2/expenses', params: payload('expenses', expense_attrs), headers: JSONAPI.merge(basic_auth)

        assert_response :forbidden

        patch "/api/v2/expenses/#{expenses(:pending).id}/review",
              params: payload('expenses', { status: 'rejected' }), headers: JSONAPI.merge(basic_auth)

        assert_response :forbidden
      end

      # --- expenses: writes

      test 'employee creates expense for self and cannot choose another employee' do
        login_as(:pascal)

        post '/api/v2/expenses', params: payload('expenses', expense_attrs), headers: JSONAPI

        assert_response :created
        assert_equal employees(:pascal).id, json_body.dig('data', 'attributes', 'employee_id')
        assert_equal 'pending', json_body.dig('data', 'attributes', 'status')

        login_as(:pascal)
        assert_no_difference('Expense.count') do
          post '/api/v2/expenses', params: payload('expenses', expense_attrs.merge(employee_id: employees(:lucien).id)),
                                   headers: JSONAPI
        end
        assert_response :bad_request
      end

      test 'management may create for another employee' do
        login_as(:mark)

        post '/api/v2/expenses', params: payload('expenses', expense_attrs.merge(employee_id: employees(:lucien).id)),
                                 headers: JSONAPI

        assert_response :created
        assert_equal employees(:lucien).id, json_body.dig('data', 'attributes', 'employee_id')
      end

      test 'expense validations render as 422' do
        login_as(:pascal)

        post '/api/v2/expenses', params: payload('expenses', expense_attrs.merge(description: nil)), headers: JSONAPI

        assert_response :unprocessable_entity
        assert_equal '/data/attributes/description', json_body['errors'].first.dig('source', 'pointer')
      end

      test 'status and review fields are not writable through crud' do
        expense = expenses(:pending)

        %w[status reviewer_id reimbursement_date reason submission_date reviewed_at].each do |attribute|
          login_as(:mark)
          patch "/api/v2/expenses/#{expense.id}", params: payload('expenses', { attribute => '2019-03-01' }, expense.id),
                                                  headers: JSONAPI

          assert_response :bad_request, attribute
        end
        assert_predicate expense.reload, :pending?
      end

      test 'owner cannot update or delete approved expense, management can' do
        approved = expenses(:approved)
        login_as(:pascal)

        patch "/api/v2/expenses/#{approved.id}", params: payload('expenses', { description: 'new' }, approved.id),
                                                 headers: JSONAPI

        assert_response :forbidden

        login_as(:pascal)
        delete "/api/v2/expenses/#{approved.id}", headers: JSONAPI

        assert_response :forbidden
        assert Expense.exists?(approved.id)

        login_as(:mark)
        patch "/api/v2/expenses/#{approved.id}", params: payload('expenses', { description: 'new' }, approved.id),
                                                 headers: JSONAPI

        assert_response :ok
        assert_equal 'new', approved.reload.description
      end

      test 'owner deletes own pending expense' do
        login_as(:pascal)

        assert_difference('Expense.count', -1) do
          delete "/api/v2/expenses/#{expenses(:pending).id}", headers: JSONAPI
        end
        assert_response :ok
      end

      test 'owner update of rejected expense resubmits it' do
        login_as(:pascal)
        rejected = expenses(:rejected)

        patch "/api/v2/expenses/#{rejected.id}", params: payload('expenses', { description: 'fixed' }, rejected.id),
                                                 headers: JSONAPI

        assert_response :ok
        rejected.reload

        assert_predicate rejected, :pending?
        assert_equal Time.zone.today, rejected.submission_date
      end

      test 'management update of rejected expense does not resubmit' do
        login_as(:mark)
        rejected = expenses(:rejected)

        patch "/api/v2/expenses/#{rejected.id}", params: payload('expenses', { description: 'fixed' }, rejected.id),
                                                 headers: JSONAPI

        assert_predicate rejected.reload, :rejected?
      end

      # --- receipt

      test 'receipt upload resizes image, detects type from content and can be read back' do
        login_as(:pascal)
        expense = expenses(:pending)
        Settings.expenses.receipt.max_pixel = 100

        put "/api/v2/expenses/#{expense.id}/receipt", params: receipt_body(PNG.read, 'scan.bin'), headers: JSONAPI

        assert_response :ok
        blob = expense.reload.receipt.blob

        assert_equal 'scan.jpg', blob.filename.to_s
        assert_equal 'image/jpeg', blob.content_type

        login_as(:pascal)
        get "/api/v2/expenses/#{expense.id}/receipt", headers: JSONAPI

        assert_response :ok
        attributes = json_body.dig('data', 'attributes')

        assert_equal 'image/jpeg', attributes['content_type']
        assert_equal blob.byte_size, attributes['data_base64'].unpack1('m0').bytesize
      end

      test 'receipt of an expense without receipt is 404' do
        login_as(:pascal)

        assert_equal 404, status_of("/api/v2/expenses/#{expenses(:pending).id}/receipt")
      end

      test 'receipt of unsupported type is rejected' do
        login_as(:pascal)

        put "/api/v2/expenses/#{expenses(:pending).id}/receipt", params: receipt_body('just text', 'a.png'),
                                                                 headers: JSONAPI

        assert_response :unprocessable_entity
        assert_equal '/data/attributes/receipt', json_body['errors'].first.dig('source', 'pointer')
        assert_not expenses(:pending).reload.receipt.attached?
      end

      test 'receipt with invalid base64 or oversize is rejected' do
        login_as(:pascal)
        path = "/api/v2/expenses/#{expenses(:pending).id}/receipt"

        put path, params: payload('expenses', { filename: 'a.png', data_base64: '***' }), headers: JSONAPI

        assert_response :unprocessable_entity

        login_as(:pascal)
        put path, params: receipt_body("\0".b * (ExpensesController::RECEIPT_MAX_BYTES + 1), 'a.png'), headers: JSONAPI

        assert_response :unprocessable_entity
        assert_match(/too large/, json_body['errors'].first['detail'])
      end

      test 'receipt of foreign or approved expense is refused' do
        other = create_expense(:lucien)
        login_as(:pascal)

        put "/api/v2/expenses/#{other.id}/receipt", params: receipt_body(PNG.read, 'a.png'), headers: JSONAPI

        assert_response :not_found

        login_as(:pascal)
        put "/api/v2/expenses/#{expenses(:approved).id}/receipt", params: receipt_body(PNG.read, 'a.png'),
                                                                  headers: JSONAPI

        assert_response :forbidden
      end

      test 'receipt upload by owner of rejected expense resubmits it' do
        login_as(:pascal)
        rejected = expenses(:rejected)

        put "/api/v2/expenses/#{rejected.id}/receipt", params: receipt_body(PNG.read, 'a.png'), headers: JSONAPI

        assert_response :ok
        assert_predicate rejected.reload, :pending?
        assert_predicate rejected.receipt, :attached?
      end

      # --- review

      test 'management approves, reviewer is set server side' do
        login_as(:mark)
        expense = expenses(:pending)

        patch "/api/v2/expenses/#{expense.id}/review",
              params: payload('expenses', { status: 'approved', reimbursement_date: '2019-03-01',
                                            reviewer_id: employees(:lucien).id }),
              headers: JSONAPI

        assert_response :ok
        expense.reload

        assert_predicate expense, :approved?
        assert_equal employees(:mark), expense.reviewer
        assert_not_nil expense.reviewed_at
        assert_equal Date.new(2019, 3, 1), expense.reimbursement_date
        assert_equal 'approved', json_body.dig('data', 'attributes', 'status')
      end

      test 'rejecting drops reimbursement date and stores reason' do
        login_as(:mark)
        expense = expenses(:pending)

        patch "/api/v2/expenses/#{expense.id}/review",
              params: payload('expenses', { status: 'rejected', reimbursement_date: '2019-03-01',
                                            reason: 'no receipt' }),
              headers: JSONAPI

        assert_response :ok
        expense.reload

        assert_predicate expense, :rejected?
        assert_nil expense.reimbursement_date
        assert_equal 'no receipt', expense.reason
      end

      test 'deferred expense can be reviewed again' do
        login_as(:mark)

        patch "/api/v2/expenses/#{expenses(:deferred).id}/review",
              params: payload('expenses', { status: 'approved', reimbursement_date: '2019-03-01' }), headers: JSONAPI

        assert_response :ok
      end

      test 'approving without reimbursement date is 422' do
        login_as(:mark)

        patch "/api/v2/expenses/#{expenses(:pending).id}/review", params: payload('expenses', { status: 'approved' }),
                                                                  headers: JSONAPI

        assert_response :unprocessable_entity
        assert_predicate expenses(:pending).reload, :pending?
      end

      test 'already reviewed expense cannot be reviewed again' do
        login_as(:mark)

        patch "/api/v2/expenses/#{expenses(:approved).id}/review", params: payload('expenses', { status: 'rejected' }),
                                                                   headers: JSONAPI

        assert_response :unprocessable_entity
        assert_equal '/data/attributes/status', json_body['errors'].first.dig('source', 'pointer')
        assert_predicate expenses(:approved).reload, :approved?
      end

      test 'invalid review status is 400' do
        login_as(:mark)

        patch "/api/v2/expenses/#{expenses(:pending).id}/review", params: payload('expenses', { status: 'pending' }),
                                                                  headers: JSONAPI

        assert_response :bad_request
      end

      test 'employee cannot review own expense' do
        login_as(:pascal)

        patch "/api/v2/expenses/#{expenses(:pending).id}/review",
              params: payload('expenses', { status: 'approved', reimbursement_date: '2019-03-01' }), headers: JSONAPI

        assert_response :forbidden
        assert_predicate expenses(:pending).reload, :pending?
      end

      # --- overtime vacations

      test 'overtime vacations are management only' do
        login_as(:pascal)

        assert_equal 403, status_of('/api/v2/overtime_vacations')

        login_as(:pascal)
        post '/api/v2/overtime_vacations',
             params: payload('overtime_vacations', { employee_id: employees(:pascal).id, hours: 5,
                                                     transfer_date: '2020-01-01' }),
             headers: JSONAPI

        assert_response :forbidden
      end

      test 'management manages overtime vacations, employee is create only' do
        login_as(:mark)
        post '/api/v2/overtime_vacations',
             params: payload('overtime_vacations', { employee_id: employees(:lucien).id, hours: 5,
                                                     transfer_date: '2020-01-01' }),
             headers: JSONAPI

        assert_response :created
        id = json_body.dig('data', 'id')

        patch "/api/v2/overtime_vacations/#{id}", params: payload('overtime_vacations', { hours: 7.5 }, id),
                                                  headers: JSONAPI

        assert_in_delta(7.5, json_body.dig('data', 'attributes', 'hours'))

        patch "/api/v2/overtime_vacations/#{id}",
              params: payload('overtime_vacations', { employee_id: employees(:pascal).id }, id), headers: JSONAPI

        assert_equal employees(:lucien).id, OvertimeVacation.find(id).employee_id

        patch "/api/v2/overtime_vacations/#{id}", params: payload('overtime_vacations', { hours: -1 }, id),
                                                  headers: JSONAPI

        assert_response :unprocessable_entity

        assert_equal [id.to_i], ids('/api/v2/overtime_vacations', filter: { employee_id: employees(:lucien).id })

        delete "/api/v2/overtime_vacations/#{id}", headers: JSONAPI

        assert_response :ok
      end

      # --- employments

      test 'employee sees only own employments' do
        login_as(:various_pedro)

        assert_equal Employment.where(employee_id: 2).pluck(:id).sort, ids('/api/v2/employments').sort

        login_as(:various_pedro)

        assert_empty ids('/api/v2/employments', filter: { employee_id: employees(:half_year_maria).id })

        login_as(:various_pedro)

        assert_equal 404, status_of("/api/v2/employments/#{employments(:for_half_year).id}")
      end

      test 'employment is rendered with its roles on include' do
        login_as(:mark)

        get "/api/v2/employments/#{open_employment.id}", params: { include: 'employment_roles_employments' },
                                                         headers: JSONAPI

        assert_response :ok
        role = json_body['included'].first['attributes']

        assert_equal employment_roles(:software_developer).id, role['employment_role_id']
        assert_equal employment_role_levels(:junior).id, role['employment_role_level_id']
      end

      test 'employees cannot write employments, api client sees nothing' do
        login_as(:various_pedro)
        patch "/api/v2/employments/#{open_employment.id}",
              params: payload('employments', { comment: 'x' }, open_employment.id), headers: JSONAPI

        assert_response :forbidden

        login_as(:various_pedro)
        post '/api/v2/employments', params: employment_body(roles: [role_attrs(100)]),
                                    headers: JSONAPI

        assert_response :forbidden

        get '/api/v2/employments', headers: JSONAPI.merge(basic_auth)

        assert_response :ok
        assert_empty json_body['data']
      end

      test 'management creates employment with roles and closes the previous one' do
        login_as(:mark)

        assert_difference(['Employment.count', 'EmploymentRolesEmployment.count']) do
          post '/api/v2/employments', params: employment_body(roles: [role_attrs(100)]),
                                      headers: JSONAPI
        end

        assert_response :created
        assert_equal Date.new(2006, 12, 31), Employment.find(4).end_date
      end

      test 'role percents must add up to employment percent' do
        login_as(:mark)

        assert_no_difference('Employment.count') do
          post '/api/v2/employments', params: employment_body(percent: 80, roles: [role_attrs(100)]),
                                      headers: JSONAPI
        end

        assert_response :unprocessable_entity
        assert_equal '/data/attributes/percent', json_body['errors'].first.dig('source', 'pointer')
      end

      test 'duplicate roles are rejected' do
        login_as(:mark)

        assert_no_difference('Employment.count') do
          post '/api/v2/employments',
               params: employment_body(roles: [role_attrs(50), role_attrs(50)]), headers: JSONAPI
        end

        assert_response :unprocessable_entity
      end

      test 'destroyed roles do not count for percent or uniqueness' do
        login_as(:mark)
        employment = open_employment
        existing = employment.employment_roles_employments.first
        second = employment_roles(:software_engineer)

        patch "/api/v2/employments/#{employment.id}",
              params: employment_body(id: employment.id, percent: 50,
                                      roles: [{ id: existing.id, _destroy: true },
                                              role_attrs(50).merge(employment_role_id: second.id)]),
              headers: JSONAPI

        assert_response :ok
        assert_equal [second.id], employment.reload.employment_roles_employments.pluck(:employment_role_id)
      end

      test 'role of an employment can be updated' do
        login_as(:mark)
        employment = open_employment
        role = employment.employment_roles_employments.first

        patch "/api/v2/employments/#{employment.id}",
              params: employment_body(id: employment.id, percent: 80,
                                      roles: [{ id: role.id, percent: 80 }]),
              headers: JSONAPI

        assert_response :ok
        assert_equal 80, role.reload.percent
      end

      test 'overlapping employment is 422' do
        login_as(:mark)

        post '/api/v2/employments',
             params: employment_body(start_date: '2006-03-01', roles: [role_attrs(100)]),
             headers: JSONAPI

        assert_response :unprocessable_entity
        assert_match(/bereits eine andere Anstellung/, json_body['errors'].pluck('detail').join)
      end

      test 'invalid previous employment surfaces as 422, not 500' do
        login_as(:mark)
        open_employment.update_columns(percent: 300)

        post '/api/v2/employments', params: employment_body(roles: [role_attrs(100)]),
                                    headers: JSONAPI

        assert_response :unprocessable_entity
        assert_equal '/data/attributes/previous_employment', json_body['errors'].first.dig('source', 'pointer')
        assert_nil Employment.find_by(employee_id: 2, start_date: '2007-01-01')
      end

      test 'role without required level is 422 and keys other than the role columns are ignored' do
        login_as(:mark)
        role = role_attrs(100).merge(employment_role_level_id: nil)

        assert_no_difference('Employment.count') do
          post '/api/v2/employments', params: employment_body(roles: [role]), headers: JSONAPI
        end
        assert_response :unprocessable_entity

        login_as(:mark)
        post '/api/v2/employments',
             params: employment_body(roles: [role_attrs(100).merge(employment_id: 1)]),
             headers: JSONAPI

        assert_response :created
        assert_equal 1, EmploymentRolesEmployment.where(employment_id: 1).count
      end

      test 'roles cannot be sideposted, the percent and uniqueness checks would be bypassed' do
        login_as(:mark)
        employment = open_employment
        reference = { type: 'employment_roles_employments', 'temp-id': 'r1', method: 'create' }
        body = { data: { type: 'employments', id: employment.id.to_s,
                         relationships: { employment_roles_employments: { data: [reference] } } },
                 included: [{ type: 'employment_roles_employments', 'temp-id': 'r1', attributes: role_attrs(50) }] }

        assert_no_difference('EmploymentRolesEmployment.count') do
          patch "/api/v2/employments/#{employment.id}", params: body.to_json, headers: JSONAPI
        end
        assert_response :bad_request
      end

      test 'employee includes the roles of own employments only' do
        login_as(:various_pedro)

        get '/api/v2/employments', params: { include: 'employment_roles_employments' }, headers: JSONAPI

        own = EmploymentRolesEmployment.where(employment_id: Employment.where(employee_id: 2).select(:id))

        assert_equal own.pluck(:id).sort, json_body['included'].pluck('id').map(&:to_i).sort
      end

      test 'employee_id of employment cannot be changed' do
        login_as(:mark)
        employment = open_employment

        patch "/api/v2/employments/#{employment.id}", params: payload('employments', { employee_id: 3 }, employment.id),
                                                      headers: JSONAPI

        assert_response :ok
        assert_equal 2, employment.reload.employee_id
      end

      private

      def open_employment
        Employment.find_by!(employee_id: 2, end_date: nil)
      end

      def expense_attrs
        { kind: 'other', amount: '12.50', payment_date: '2026-01-05', description: 'train' }
      end

      def create_expense(employee)
        Expense.create!(expense_attrs.merge(employee: employees(employee)))
      end

      def receipt_body(data, filename)
        payload('expenses', { filename:, data_base64: [data.b].pack('m0') })
      end

      def role_attrs(percent)
        { employment_role_id: employment_roles(:software_developer).id,
          employment_role_level_id: employment_role_levels(:junior).id, percent: }
      end

      # Employment document; the roles are nested attributes (`id` updates a role, `_destroy: true` removes it).
      def employment_body(roles:, id: nil, **attributes)
        attributes = { employee_id: 2, percent: 100, start_date: '2007-01-01' }.merge(attributes) unless id
        payload('employments', attributes.merge(employment_roles_employments_attributes: roles), id)
      end
    end
  end
end
