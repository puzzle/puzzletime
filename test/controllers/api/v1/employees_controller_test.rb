# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V1
    class EmployeesControllerTest < ActionController::TestCase
      setup do
        request.headers['Authorization'] = basic_auth_header
        request.headers['Accept'] = Mime::Type.lookup_by_extension(:jsonapi).to_s
      end

      test 'show' do
        get :show, params: { id: test_entry.id }

        assert_response :ok
        assert_match %r{\Aapplication/vnd\.api\+json}, response.headers['Content-Type']
        assert_equal test_entry.id.to_s, response_json[:data][:id]
      end

      test 'show with unknown includes parameter' do
        get :show, params: { id: employees(:long_time_john).id, include: 'current_employment' }

        assert_response :unprocessable_entity
        assert_match %r{\Aapplication/vnd\.api\+json}, response.headers['Content-Type']
        assert_equal '422', response_json.dig(:errors, 0, :status)
        assert_equal 'error', response_json.dig(:errors, 0, :code)
        assert_match(/current_employment is not specified as a relationship/, response_json.dig(:errors, 0, :title))
      end

      test 'index' do
        get :index

        assert_response :ok
        assert_match %r{\Aapplication/vnd\.api\+json}, response.headers['Content-Type']
        assert_equal Employee.count, response_json[:data].count
      end

      test 'index with scope parameter' do
        get :index, params: { scope: :current }

        assert_response :ok
        assert_match %r{\Aapplication/vnd\.api\+json}, response.headers['Content-Type']
        assert_equal Employee.current.count, response_json[:data].count
      end

      test 'index filtered by email returns only the matching employee' do
        get :index, params: { filter: { email: test_entry.email } }

        assert_response :ok
        ids = response_json[:data].map { |d| d[:id].to_i }

        assert_equal [test_entry.id], ids
      end

      test 'index filtered by ldapname returns only the matching employee' do
        get :index, params: { filter: { ldapname: test_entry.ldapname } }

        assert_response :ok
        ids = response_json[:data].map { |d| d[:id].to_i }

        assert_equal [test_entry.id], ids
      end

      test 'index with multiple filters combines them with AND' do
        get :index, params: { filter: { email: test_entry.email, ldapname: 'does-not-match' } }

        assert_response :ok
        assert_empty response_json[:data]
      end

      test 'index with an unknown filter attribute ignores it' do
        get :index, params: { filter: { firstname: test_entry.firstname } }

        assert_response :ok
        assert_equal Employee.count, response_json[:data].count
      end

      test 'index filtered by keycloakopenid uses the custom join filter' do
        auth = authentications(:one)
        get :index, params: { filter: { keycloakopenid: auth.uid } }

        assert_response :ok
        ids = response_json[:data].map { |d| d[:id].to_i }

        assert_equal [auth.employee_id], ids
      end

      (1..3).each do |i|
        test "pagination per_page works with #{i}" do
          get :index, params: { per_page: i }

          assert_equal i, response_json[:data].count
        end

        test "pagination page works with #{i}" do
          get :index, params: { page: i }
          expected = Employee.list.page(i).pluck(:id)
          actual   = response_json[:data].map { |d| d[:id].to_i }

          assert_equal expected, actual
        end
      end

      test 'pagination headers are present' do
        get :index, params: { page: 2, per_page: 1 }
        list_entries = Employee.list.page(2).per(1)

        assert_equal list_entries.total_count,  response.headers['Pagination-Total-Count']
        assert_equal list_entries.limit_value,  response.headers['Pagination-Per-Page']
        assert_equal list_entries.current_page, response.headers['Pagination-Current-Page']
        assert_equal list_entries.total_pages,  response.headers['Pagination-Total-Pages']
      end

      private

      def basic_auth_header
        encoded_credentials = Base64.strict_encode64("#{Settings.api_client.user}:#{Settings.api_client.password}")
        "Basic #{encoded_credentials}"
      end

      # Test object used in several tests.
      def test_entry
        @test_entry ||= employees(:long_time_john)
      end

      def response_json
        text = response.parsed_body
        text = JSON.parse(text)

        ActiveSupport::HashWithIndifferentAccess.new(text)
      end
    end
  end
end
