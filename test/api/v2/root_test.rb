# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V2
    class RootTest < ActionDispatch::IntegrationTest
      JSON_HEADERS = { 'CONTENT_TYPE' => 'application/json' }.freeze

      test 'requires authentication' do
        get '/api/v2/departments'

        assert_response :unauthorized
      end

      test 'basic auth lists employees with pagination headers' do
        get '/api/v2/employees', headers: basic_auth

        assert_response :ok
        assert_equal Employee.list.pluck(:id), response.parsed_body.pluck('id')
        assert_equal Employee.count.to_s, response.headers['Pagination-Total-Count']
      end

      test 'api client may not read departments' do
        get '/api/v2/departments', headers: basic_auth

        assert_response :forbidden
      end

      test 'show renders only declared attributes' do
        get "/api/v2/employees/#{employees(:mark).id}", headers: basic_auth

        assert_equal %w[department_id firstname id lastname shortname workplace_id], response.parsed_body.keys.sort
      end

      test 'unknown id is 404' do
        get '/api/v2/employees/0', headers: basic_auth

        assert_response :not_found
      end

      test 'read-only resources have no write routes' do
        post '/api/v2/employees', params: '{}', headers: basic_auth.merge(JSON_HEADERS)

        assert_response :method_not_allowed
      end

      test 'api client may not write' do
        post '/api/v2/departments', params: { name: 'x', shortname: 'xx' }.to_json,
                                    headers: basic_auth.merge(JSON_HEADERS)

        assert_response :forbidden
      end

      test 'management creates, updates and deletes through the session' do
        login_as(:mark)

        post '/api/v2/departments', params: { name: 'New', shortname: 'NW' }.to_json, headers: JSON_HEADERS

        assert_response :created
        id = response.parsed_body['id']

        patch "/api/v2/departments/#{id}", params: { shortname: 'N2' }.to_json, headers: JSON_HEADERS

        assert_response :ok
        assert_equal %w[New N2], Department.find(id).slice(:name, :shortname).values

        delete "/api/v2/departments/#{id}"

        assert_response :no_content
        assert_not Department.exists?(id)
      end

      test 'validation errors render as 422' do
        login_as(:mark)

        post '/api/v2/departments', params: { name: 'New', shortname: 'TOOLONG' }.to_json, headers: JSON_HEADERS

        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'shortname'
      end

      test 'session writes require a json content type' do
        login_as(:mark)

        assert_no_difference('Department.count') do
          post '/api/v2/departments', params: { name: 'New', shortname: 'NW' }
        end
        assert_response :unsupported_media_type
      end

      test 'ordinary json routes stay untouched' do
        login_as(:mark)

        get '/departments.json'

        assert_response :ok
        assert_equal %w[id name shortname url], response.parsed_body.first.keys.sort
      end

      test 'every registered resource with an index lists for management' do
        login_as(:mark)

        Crud.resources.each_value.select { |res| res.actions.include?(:index) }.each do |res|
          get "/api/v2/#{res.model.model_name.route_key}"

          assert_response :ok, res.model.name
          keys = res.read.flat_map { |attr| attr.is_a?(Hash) ? attr.keys : attr }.map(&:to_s).sort
          row = response.parsed_body.first

          assert_equal keys, row.keys.sort, res.model.name if row
        end
      end

      test 'has_many relationship lists the related records through their own resource' do
        login_as(:mark)
        department = employees(:mark).tap { |e| e.update_column(:department_id, departments(:devone).id) }.department

        get "/api/v2/departments/#{department.id}/employees"

        assert_response :ok
        assert_equal department.employees.pluck(:id).sort, response.parsed_body.pluck('id').sort
        assert_equal %w[department_id firstname id lastname shortname workplace_id], response.parsed_body.first.keys.sort
      end

      test 'belongs_to relationship shows the related record, 404 when absent' do
        login_as(:mark)
        employee = employees(:mark).tap { |e| e.update_column(:department_id, departments(:devone).id) }

        get "/api/v2/employees/#{employee.id}/department"

        assert_response :ok
        assert_equal employee.department_id, response.parsed_body['id']

        employee.update_column(:department_id, nil)
        get "/api/v2/employees/#{employee.id}/department"

        assert_response :not_found
      end

      test 'relationships are authorized' do
        get "/api/v2/departments/#{departments(:devone).id}/employees", headers: basic_auth

        assert_response :forbidden
      end

      test 'swagger spec documents resources, relationships and response schemas' do
        login_as(:mark)

        get '/api/v2/swagger_doc'

        assert_response :ok
        spec = response.parsed_body

        assert_includes spec['paths'].keys, '/departments/{id}/employees'
        assert_equal %w[delete get patch], spec['paths']['/departments/{id}'].keys.sort
        assert_equal %w[id name shortname], spec['definitions'].fetch('Department')['properties'].keys.sort
        assert_equal({ 'type' => 'string', 'format' => 'decimal' },
                     spec['definitions']['WorkingCondition']['properties']['must_hours_per_day'])
        assert_not_includes spec['definitions']['Employee']['required'], 'department_id'
      end

      private

      def basic_auth
        { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(
          Settings.api_client.user, Settings.api_client.password
        ) }
      end
    end
  end
end
