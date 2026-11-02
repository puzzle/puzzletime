# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V2
    class ExpensesTest < ActionDispatch::IntegrationTest
      JSON_HEADERS = { 'CONTENT_TYPE' => 'application/json' }.freeze
      PNG = Rails.root.join('test/fixtures/files/lorem-ipsum.png')

      # --- expenses: scope isolation

      test 'employee lists and shows only own expenses' do
        login_as(:pascal)
        get '/api/v2/expenses'

        assert_response :ok
        assert_equal Expense.where(employee_id: employees(:pascal).id).count, response.parsed_body.size

        other = Expense.create!(employee: employees(:lucien), kind: :other, amount: 1, payment_date: Time.zone.today,
                                description: 'x')
        get "/api/v2/expenses/#{other.id}"

        assert_response :not_found
      end

      test 'management sees all expenses' do
        login_as(:mark)
        get '/api/v2/expenses', params: { per_page: 100 }

        assert_equal Expense.count, response.parsed_body.size
      end

      test 'employee cannot update or delete foreign expenses' do
        other = create_expense(:lucien)
        login_as(:pascal)

        patch "/api/v2/expenses/#{other.id}", params: { description: 'hack' }.to_json, headers: JSON_HEADERS

        assert_response :not_found

        delete "/api/v2/expenses/#{other.id}"

        assert_response :not_found
        assert Expense.exists?(other.id)
      end

      test 'employee relationship list is scoped' do
        create_expense(:lucien)
        login_as(:pascal)

        get "/api/v2/employees/#{employees(:lucien).id}/expenses"

        assert_response :ok
        assert_empty response.parsed_body

        get "/api/v2/employees/#{employees(:pascal).id}/expenses"

        assert_equal Expense.where(employee_id: employees(:pascal).id).count, response.parsed_body.size
      end

      test 'api client sees no expenses and cannot write' do
        get '/api/v2/expenses', headers: basic_auth

        assert_response :ok
        assert_empty response.parsed_body

        post '/api/v2/expenses', params: expense_attrs.to_json, headers: JSON_HEADERS.merge(basic_auth)

        assert_response :forbidden

        patch "/api/v2/expenses/#{expenses(:pending).id}/review", params: { status: 'rejected' }.to_json,
                                                                  headers: JSON_HEADERS.merge(basic_auth)

        assert_response :forbidden
      end

      # --- expenses: writes

      test 'employee creates expense for self and cannot choose another employee' do
        login_as(:pascal)

        post '/api/v2/expenses', params: expense_attrs.to_json, headers: JSON_HEADERS

        assert_response :created
        assert_equal employees(:pascal).id, response.parsed_body['employee_id']
        assert_equal 'pending', response.parsed_body['status']

        post '/api/v2/expenses', params: expense_attrs.merge(employee_id: employees(:lucien).id).to_json,
                                 headers: JSON_HEADERS

        assert_response :forbidden
      end

      test 'management may create for another employee' do
        login_as(:mark)

        post '/api/v2/expenses', params: expense_attrs.merge(employee_id: employees(:lucien).id).to_json,
                                 headers: JSON_HEADERS

        assert_response :created
        assert_equal employees(:lucien).id, response.parsed_body['employee_id']
      end

      test 'status and review fields are not writable through crud' do
        login_as(:pascal)

        patch "/api/v2/expenses/#{expenses(:pending).id}", params: { status: 'approved' }.to_json, headers: JSON_HEADERS

        assert_equal 'pending', expenses(:pending).reload.status
        assert_response :ok # undeclared params are ignored
      end

      test 'owner cannot update or delete approved expense, management can' do
        login_as(:pascal)
        approved = expenses(:approved)

        patch "/api/v2/expenses/#{approved.id}", params: { description: 'new' }.to_json, headers: JSON_HEADERS

        assert_response :forbidden

        delete "/api/v2/expenses/#{approved.id}"

        assert_response :forbidden

        login_as(:mark)
        patch "/api/v2/expenses/#{approved.id}", params: { description: 'new' }.to_json, headers: JSON_HEADERS

        assert_response :ok
        assert_equal 'new', approved.reload.description
      end

      test 'owner update of rejected expense resubmits it' do
        login_as(:pascal)
        rejected = expenses(:rejected)

        patch "/api/v2/expenses/#{rejected.id}", params: { description: 'fixed' }.to_json, headers: JSON_HEADERS

        assert_response :ok
        rejected.reload

        assert_predicate rejected, :pending?
        assert_equal Time.zone.today, rejected.submission_date
      end

      test 'management update of rejected expense does not resubmit' do
        login_as(:mark)
        rejected = expenses(:rejected)

        patch "/api/v2/expenses/#{rejected.id}", params: { description: 'fixed' }.to_json, headers: JSON_HEADERS

        assert_predicate rejected.reload, :rejected?
      end

      # --- receipt

      test 'receipt upload resizes image, detects type from content and can be read back' do
        login_as(:pascal)
        expense = expenses(:pending)
        Settings.expenses.receipt.max_pixel = 100

        put "/api/v2/expenses/#{expense.id}/receipt", params: receipt_json(PNG.read, 'scan.bin'), headers: JSON_HEADERS

        assert_response :ok
        blob = expense.reload.receipt.blob

        assert_equal 'scan.jpg', blob.filename.to_s
        assert_equal 'image/jpeg', blob.content_type

        get "/api/v2/expenses/#{expense.id}/receipt"

        assert_response :ok
        assert_equal 'image/jpeg', response.parsed_body['content_type']
        assert_equal blob.byte_size, response.parsed_body['data_base64'].unpack1('m0').bytesize
      end

      test 'receipt of unsupported type is rejected' do
        login_as(:pascal)

        put "/api/v2/expenses/#{expenses(:pending).id}/receipt", params: receipt_json('just text', 'a.png'),
                                                                 headers: JSON_HEADERS

        assert_response :unprocessable_entity
        assert response.parsed_body['errors'].key?('receipt')
        assert_not expenses(:pending).reload.receipt.attached?
      end

      test 'receipt with invalid base64 or oversize is rejected' do
        login_as(:pascal)
        path = "/api/v2/expenses/#{expenses(:pending).id}/receipt"

        put path, params: { filename: 'a.png', data_base64: '***' }.to_json, headers: JSON_HEADERS

        assert_response :unprocessable_entity

        put path, params: receipt_json("\0".b * (Resources::Expenses::RECEIPT_MAX_BYTES + 1), 'a.png'),
                  headers: JSON_HEADERS

        assert_response :unprocessable_entity
        assert_match(/too large/, response.parsed_body['errors']['receipt'].first)
      end

      test 'receipt of foreign or approved expense is refused' do
        other = create_expense(:lucien)
        login_as(:pascal)

        put "/api/v2/expenses/#{other.id}/receipt", params: receipt_json(PNG.read, 'a.png'), headers: JSON_HEADERS

        assert_response :not_found

        put "/api/v2/expenses/#{expenses(:approved).id}/receipt", params: receipt_json(PNG.read, 'a.png'),
                                                                  headers: JSON_HEADERS

        assert_response :forbidden
      end

      # --- review

      test 'management approves, reviewer is set server side' do
        login_as(:mark)
        expense = expenses(:pending)

        patch "/api/v2/expenses/#{expense.id}/review",
              params: { status: 'approved', reimbursement_date: '2019-03-01', reviewer_id: employees(:lucien).id }.to_json,
              headers: JSON_HEADERS

        assert_response :ok
        expense.reload

        assert_predicate expense, :approved?
        assert_equal employees(:mark), expense.reviewer
        assert_not_nil expense.reviewed_at
        assert_equal Date.new(2019, 3, 1), expense.reimbursement_date
      end

      test 'rejecting drops reimbursement date and stores reason' do
        login_as(:mark)
        expense = expenses(:pending)

        patch "/api/v2/expenses/#{expense.id}/review",
              params: { status: 'rejected', reimbursement_date: '2019-03-01', reason: 'no receipt' }.to_json,
              headers: JSON_HEADERS

        assert_response :ok
        expense.reload

        assert_predicate expense, :rejected?
        assert_nil expense.reimbursement_date
        assert_equal 'no receipt', expense.reason
      end

      test 'approving without reimbursement date is 422' do
        login_as(:mark)

        patch "/api/v2/expenses/#{expenses(:pending).id}/review", params: { status: 'approved' }.to_json,
                                                                  headers: JSON_HEADERS

        assert_response :unprocessable_entity
        assert_predicate expenses(:pending).reload, :pending?
      end

      test 'already reviewed expense cannot be reviewed again' do
        login_as(:mark)

        patch "/api/v2/expenses/#{expenses(:approved).id}/review", params: { status: 'rejected' }.to_json,
                                                                   headers: JSON_HEADERS

        assert_response :unprocessable_entity
        assert_predicate expenses(:approved).reload, :approved?
      end

      test 'invalid review status is 400' do
        login_as(:mark)

        patch "/api/v2/expenses/#{expenses(:pending).id}/review", params: { status: 'pending' }.to_json,
                                                                  headers: JSON_HEADERS

        assert_response :bad_request
      end

      test 'employee cannot review own expense' do
        login_as(:pascal)

        patch "/api/v2/expenses/#{expenses(:pending).id}/review",
              params: { status: 'approved', reimbursement_date: '2019-03-01' }.to_json, headers: JSON_HEADERS

        assert_response :forbidden
        assert_predicate expenses(:pending).reload, :pending?
      end

      # --- overtime vacations

      test 'overtime vacations are management only' do
        login_as(:pascal)
        get '/api/v2/overtime_vacations'

        assert_response :forbidden

        get "/api/v2/employees/#{employees(:pascal).id}/overtime_vacations"

        assert_response :forbidden
      end

      test 'management manages overtime vacations, employee is create only' do
        login_as(:mark)
        post '/api/v2/overtime_vacations',
             params: { employee_id: employees(:lucien).id, hours: 5, transfer_date: '2020-01-01' }.to_json,
             headers: JSON_HEADERS

        assert_response :created
        id = response.parsed_body['id']

        patch "/api/v2/overtime_vacations/#{id}", params: { hours: 7.5 }.to_json, headers: JSON_HEADERS

        assert_in_delta(7.5, response.parsed_body['hours'])

        patch "/api/v2/overtime_vacations/#{id}", params: { employee_id: employees(:pascal).id }.to_json,
                                                  headers: JSON_HEADERS

        assert_equal employees(:lucien).id, OvertimeVacation.find(id).employee_id

        patch "/api/v2/overtime_vacations/#{id}", params: { hours: -1 }.to_json, headers: JSON_HEADERS

        assert_response :unprocessable_entity

        get "/api/v2/employees/#{employees(:lucien).id}/overtime_vacations"

        assert_equal [id], response.parsed_body.pluck('id')
      end

      # --- employments

      test 'employee sees only own employments' do
        login_as(:various_pedro)
        get '/api/v2/employments'

        assert_response :ok
        assert_equal(Employment.where(employee_id: 2).pluck(:id).sort, response.parsed_body.pluck('id').sort)

        get "/api/v2/employments/#{employments(:for_half_year).id}"

        assert_response :not_found

        get "/api/v2/employees/#{employees(:half_year_maria).id}/employments"

        assert_response :ok
        assert_empty response.parsed_body
      end

      test 'employment is rendered with its roles' do
        login_as(:mark)

        get "/api/v2/employments/#{open_employment.id}"

        assert_response :ok
        role = response.parsed_body['employment_roles_employments'].first

        assert_equal employment_roles(:software_developer).id, role['employment_role_id']
        assert_equal employment_role_levels(:junior).id, role['employment_role_level_id']
      end

      test 'employees cannot write employments, api client sees nothing' do
        login_as(:various_pedro)
        patch "/api/v2/employments/#{open_employment.id}", params: { comment: 'x' }.to_json,
                                                           headers: JSON_HEADERS

        assert_response :forbidden

        post '/api/v2/employments', params: employment_attrs(employee_id: 2).to_json, headers: JSON_HEADERS

        assert_response :forbidden

        get '/api/v2/employments', headers: basic_auth

        assert_response :ok
        assert_empty response.parsed_body
      end

      test 'management creates employment and closes the previous one' do
        login_as(:mark)

        post '/api/v2/employments', params: employment_attrs(employee_id: 2).to_json, headers: JSON_HEADERS

        assert_response :created
        assert_equal 1, response.parsed_body['employment_roles_employments'].size
        assert_equal Date.new(2006, 12, 31), Employment.find(4).end_date
      end

      test 'role percents must add up to employment percent' do
        login_as(:mark)
        attrs = employment_attrs(employee_id: 2, percent: 80)

        post '/api/v2/employments', params: attrs.to_json, headers: JSON_HEADERS

        assert_response :unprocessable_entity
        assert response.parsed_body['errors'].key?('percent')
      end

      test 'duplicate roles are rejected' do
        login_as(:mark)
        attrs = employment_attrs(employee_id: 2, percent: 100)
        attrs[Resources::Expenses::ROLES_KEY] = [role_attrs(50), role_attrs(50)]

        post '/api/v2/employments', params: attrs.to_json, headers: JSON_HEADERS

        assert_response :unprocessable_entity
        assert response.parsed_body['errors'].key?('employment_roles_employments')
      end

      test 'destroyed roles do not count for percent or uniqueness' do
        login_as(:mark)
        employment = open_employment
        existing = employment.employment_roles_employments.first
        second = employment_roles(:software_engineer)

        patch "/api/v2/employments/#{employment.id}",
              params: { percent: 50,
                        Resources::Expenses::ROLES_KEY => [
                          { id: existing.id, _destroy: true },
                          { employment_role_id: second.id, employment_role_level_id: employment_role_levels(:junior).id,
                            percent: 50 }
                        ] }.to_json,
              headers: JSON_HEADERS

        assert_response :ok
        assert_equal [second.id], employment.reload.employment_roles_employments.pluck(:employment_role_id)

        # "_destroy": false must not destroy
        role = employment.employment_roles_employments.first
        patch "/api/v2/employments/#{employment.id}",
              params: { Resources::Expenses::ROLES_KEY => [{ id: role.id, percent: 50, _destroy: false }] }.to_json,
              headers: JSON_HEADERS

        assert_response :ok
        assert_equal 1, employment.reload.employment_roles_employments.count
      end

      test 'overlapping employment is 422' do
        login_as(:mark)

        post '/api/v2/employments', params: employment_attrs(employee_id: 2, start_date: '2006-03-01').to_json,
                                    headers: JSON_HEADERS

        assert_response :unprocessable_entity
        assert_match(/bereits eine andere Anstellung/, response.parsed_body['errors'].values.join)
      end

      test 'invalid previous employment surfaces as 422, not 500' do
        login_as(:mark)
        open_employment.update_columns(percent: 300)

        post '/api/v2/employments', params: employment_attrs(employee_id: 2).to_json, headers: JSON_HEADERS

        assert_response :unprocessable_entity
        assert response.parsed_body['errors'].key?('previous_employment')
        assert_nil Employment.find_by(employee_id: 2, start_date: '2007-01-01')
      end

      test 'employee_id of employment cannot be changed' do
        login_as(:mark)
        employment = open_employment

        patch "/api/v2/employments/#{employment.id}", params: { employee_id: 3 }.to_json, headers: JSON_HEADERS

        assert_response :ok # create-only attribute is ignored on update
        assert_equal 2, employment.reload.employee_id
      end

      test 'swagger documents the new resources' do
        login_as(:mark)

        get '/api/v2/swagger_doc'

        assert_response :ok
        paths = response.parsed_body['paths']

        %w[/expenses /expenses/{id}/receipt /expenses/{id}/review /employments
           /overtime_vacations /employees/{id}/expenses /employees/{id}/employments
           /employees/{id}/overtime_vacations].each do |path|
          assert_includes paths.keys, path
        end
        assert_not_includes response.parsed_body['definitions']['Expense']['properties'].keys, 'receipt'
        assert_includes response.parsed_body['definitions'].keys, 'EmploymentEmploymentRolesEmployments'
      end

      private

      def basic_auth
        { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(
          Settings.api_client.user, Settings.api_client.password
        ) }
      end

      def open_employment
        Employment.find_by!(employee_id: 2, end_date: nil)
      end

      def expense_attrs
        { kind: 'other', amount: '12.50', payment_date: '2026-01-05', description: 'train' }
      end

      def create_expense(employee)
        Expense.create!(expense_attrs.merge(employee: employees(employee)))
      end

      def receipt_json(data, filename)
        { filename:, data_base64: [data.b].pack('m0') }.to_json
      end

      def role_attrs(percent)
        { employment_role_id: employment_roles(:software_developer).id,
          employment_role_level_id: employment_role_levels(:junior).id, percent: }
      end

      def employment_attrs(employee_id:, percent: 100, start_date: '2007-01-01')
        { employee_id:, percent:, start_date:, Resources::Expenses::ROLES_KEY => [role_attrs(100)] }
      end
    end
  end
end
