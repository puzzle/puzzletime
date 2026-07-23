# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V1
    class OrdersControllerTest < ActionController::TestCase
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
        get :show, params: { id: orders(:hitobito_demo).id, include: 'test' }

        assert_response :unprocessable_entity
        assert_match %r{\Aapplication/vnd\.api\+json}, response.headers['Content-Type']
        assert_equal '422', response_json.dig(:errors, 0, :status)
        assert_equal 'error', response_json.dig(:errors, 0, :code)
        assert_match(/test is not specified as a relationship/, response_json.dig(:errors, 0, :title))
      end

      test 'index' do
        get :index

        assert_response :ok
        assert_match %r{\Aapplication/vnd\.api\+json}, response.headers['Content-Type']
        assert_equal Order.count, response_json[:data].count
      end

      test 'index filtered by email returns the orders the employee is responsible for or a team member of' do
        get :index, params: { filter: { email: employees(:api_filter_alice).email } }

        assert_response :ok
        ids = response_json[:data].map { |d| d[:id].to_i }

        assert_equal matched_order_ids, ids.sort
      end

      test 'index filtered by ldapname returns the orders the employee is responsible for or a team member of' do
        get :index, params: { filter: { ldapname: employees(:api_filter_alice).ldapname } }

        assert_response :ok
        ids = response_json[:data].map { |d| d[:id].to_i }

        assert_equal matched_order_ids, ids.sort
      end

      test 'index filtered by keycloakopenid returns the orders the employee is responsible for or a team member of' do
        auth = authentications(:api_alice_keycloak)

        get :index, params: { filter: { keycloakopenid: auth.uid } }

        assert_response :ok
        ids = response_json[:data].map { |d| d[:id].to_i }

        assert_equal matched_order_ids, ids.sort
      end

      test 'index with multiple filters combines them with AND' do
        get :index, params: { filter: { email: employees(:api_filter_alice).email, ldapname: 'does-not-match' } }

        assert_response :ok
        assert_empty response_json[:data]
      end

      test 'index with an unknown filter attribute ignores it' do
        get :index, params: { filter: { firstname: employees(:api_filter_alice).firstname } }

        assert_response :ok
        assert_equal Order.count, response_json[:data].count
      end

      (1..3).each do |i|
        test "pagination per_page works with #{i}" do
          get :index, params: { per_page: i }

          assert_equal i, response_json[:data].count
        end

        test "pagination page works with #{i}" do
          get :index, params: { page: i }
          expected = Order.list.page(i).pluck(:id)
          actual   = response_json[:data].map { |d| d[:id].to_i }

          assert_equal expected, actual
        end
      end

      test 'pagination headers are present' do
        get :index, params: { page: 2, per_page: 1 }
        list_entries = Order.list.page(2).per(1)

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
        @test_entry ||= orders(:api_order_one)
      end

      # Orders :api_filter_alice is linked to: responsible of :api_order_one,
      # team member of :api_order_two. The filter must return both.
      def matched_order_ids
        [orders(:api_order_one).id, orders(:api_order_two).id].sort
      end

      def response_json
        text = response.parsed_body
        text = JSON.parse(text)

        ActiveSupport::HashWithIndifferentAccess.new(text)
      end
    end
  end
end
