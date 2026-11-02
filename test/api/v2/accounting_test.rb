# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V2
    # Fixture roles: mark = management, lucien = responsible of puzzletime and hitobito_demo,
    # long_time_john = responsible of webauftritt, pascal = regular employee (planned on hitobito_demo).
    class AccountingTest < ActionDispatch::IntegrationTest
      JSON_HEADERS = { 'CONTENT_TYPE' => 'application/json' }.freeze

      def post_params(order, **extra)
        { order_id: order.id, portfolio_item_id: portfolio_items(:web).id, service_id: services(:software).id,
          offered_rate: 150, offered_hours: 10, work_item_attributes: { name: 'Neue Position', shortname: 'NEU' } }
          .merge(extra)
      end

      def create_post(order, headers: {}, **extra)
        post '/api/v2/accounting_posts', params: post_params(order, **extra).to_json,
                                         headers: JSON_HEADERS.merge(headers)
      end

      def ids
        response.parsed_body.pluck('id').sort
      end

      # accounting posts

      test 'employees read posts, api client sees nothing' do
        login_as(:pascal)
        get '/api/v2/accounting_posts'

        assert_response :ok
        assert_equal AccountingPost.pluck(:id).sort, ids
        assert_not_includes response.parsed_body.first.keys, 'work_item_attributes'

        get '/api/v2/accounting_posts', headers: basic_auth

        assert_empty response.parsed_body
        get "/api/v2/accounting_posts/#{accounting_posts(:puzzletime).id}", headers: basic_auth

        assert_response :not_found
      end

      test 'api client cannot create posts' do
        assert_no_difference('AccountingPost.count') do
          create_post(orders(:puzzletime), headers: basic_auth)
        end
        assert_includes [403, 404], response.status
      end

      test 'orders posts are listed per order' do
        login_as(:pascal)

        get "/api/v2/orders/#{orders(:puzzletime).id}/accounting_posts"

        assert_response :ok
        assert_equal [accounting_posts(:puzzletime).id], ids
      end

      test 'responsible creates a post below own order through attach_work_item' do
        login_as(:lucien)
        order = orders(:hitobito_demo)

        assert_difference(['AccountingPost.count', 'WorkItem.count'], 1) { create_post(order) }

        assert_response :created
        entry = AccountingPost.find(response.parsed_body['id'])

        assert_equal order.work_item_id, entry.work_item.parent_id
        assert_equal 'Neue Position', entry.work_item.name
        assert_equal order, entry.order
        assert_not entry.booked_on_order?
      end

      test 'creating below an order that already is booked moves the existing booking' do
        login_as(:lucien)
        order = orders(:puzzletime)
        old = accounting_posts(:puzzletime)

        create_post(order)

        assert_response :created
        assert_not_equal order.work_item_id, old.reload.work_item_id
        assert_equal order.work_item_id, old.work_item.parent_id
        assert_equal 2, order.accounting_posts.count
      end

      test 'book on order attaches the order work item' do
        login_as(:mark)
        order = orders(:webauftritt)
        accounting_posts(:webauftritt).delete

        assert_no_difference('WorkItem.count') do
          create_post(order, book_on_order: true, work_item_attributes: nil)
        end

        assert_response :created
        assert_equal order.work_item_id, AccountingPost.find(response.parsed_body['id']).work_item_id
      end

      test 'book on order is rejected while other posts exist' do
        login_as(:lucien)

        assert_no_difference(['AccountingPost.count', 'WorkItem.count']) do
          create_post(orders(:puzzletime), book_on_order: true)
        end
        assert_response :unprocessable_content
      end

      test 'invalid post renders 422 and leaves no orphan work item' do
        login_as(:mark)

        assert_no_difference(['AccountingPost.count', 'WorkItem.count']) do
          create_post(orders(:webauftritt), offered_rate: nil)
        end
        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'offered_rate'
      end

      test 'post without a work item name is rejected' do
        login_as(:mark)

        assert_no_difference(['AccountingPost.count', 'WorkItem.count']) do
          create_post(orders(:webauftritt), work_item_attributes: { shortname: 'X' })
        end
        assert_response :unprocessable_content
      end

      test 'others cannot create below foreign orders' do
        { lucien: :webauftritt, pascal: :hitobito_demo, long_time_john: :puzzletime }.each do |user, order|
          login_as(user)

          assert_no_difference(['AccountingPost.count', 'WorkItem.count']) { create_post(orders(order)) }
          assert_response :forbidden, "#{user} on #{order}"
        end
      end

      test 'update renames through a new work item and moves the post' do
        login_as(:lucien)
        entry = accounting_posts(:puzzletime)
        order = orders(:puzzletime)

        patch "/api/v2/accounting_posts/#{entry.id}",
              params: { offered_hours: 50, offered_total: nil, work_item_attributes: { name: 'Split', shortname: 'SPL' } }.to_json,
              headers: JSON_HEADERS

        assert_response :ok
        assert_equal 'Split', entry.reload.work_item.name
        assert_equal order.work_item_id, entry.work_item.parent_id
        assert_equal 50, entry.offered_hours
      end

      test 'update keeping the booking on the order needs book_on_order' do
        login_as(:lucien)
        entry = accounting_posts(:puzzletime)

        patch "/api/v2/accounting_posts/#{entry.id}", params: { billable: true }.to_json, headers: JSON_HEADERS

        assert_response :unprocessable_content
        assert_equal orders(:puzzletime).work_item_id, entry.reload.work_item_id

        patch "/api/v2/accounting_posts/#{entry.id}",
              params: { billable: true, book_on_order: true }.to_json, headers: JSON_HEADERS

        assert_response :ok
        assert_predicate entry.reload, :billable?
      end

      test 'foreign responsible and employees cannot update or delete posts' do
        entry = accounting_posts(:puzzletime)
        %i[long_time_john pascal].each do |user|
          login_as(user)
          patch "/api/v2/accounting_posts/#{entry.id}", params: { billable: true, book_on_order: true }.to_json,
                                                        headers: JSON_HEADERS

          assert_response :forbidden, user

          delete "/api/v2/accounting_posts/#{entry.id}"

          assert_response :forbidden, user
        end
        assert_not entry.reload.billable?
      end

      test 'posts with worktimes cannot be deleted, others can' do
        login_as(:lucien)
        entry = accounting_posts(:puzzletime)

        assert_predicate entry.worktimes, :exists?
        delete "/api/v2/accounting_posts/#{entry.id}"

        assert_response :unprocessable_content
        assert AccountingPost.exists?(entry.id)

        create_post(orders(:hitobito_demo))
        id = response.parsed_body['id']
        delete "/api/v2/accounting_posts/#{id}"

        assert_response :no_content
        assert_not AccountingPost.exists?(id)
      end

      # invoices

      test 'invoices are scoped to management and the responsible' do
        invoice = invoices(:webauftritt_may)
        { mark: [invoice.id], long_time_john: [invoice.id], lucien: [], pascal: [] }.each do |user, expected|
          login_as(user)
          get '/api/v2/invoices'

          assert_response :ok
          assert_equal expected, ids, user.to_s

          get "/api/v2/invoices/#{invoice.id}"

          assert_response expected.empty? ? :not_found : :ok

          get "/api/v2/orders/#{invoice.order_id}/invoices"

          assert_response :ok
          assert_equal expected, ids, user.to_s
        end
      end

      test 'invoices render no internal columns and api client sees none' do
        login_as(:mark)
        get "/api/v2/invoices/#{invoices(:webauftritt_may).id}"

        assert_equal %w[billing_address_id billing_date due_date grouping id order_id period_from period_to
                        reference status total_amount total_hours], response.parsed_body.keys.sort

        get '/api/v2/invoices', headers: basic_auth

        assert_empty response.parsed_body
      end

      test 'invoices and plannings have no write routes' do
        login_as(:mark)
        invoice = invoices(:webauftritt_may)
        planning = plannings(:hitobito_demo_app_planning1)

        post '/api/v2/invoices', params: '{}', headers: JSON_HEADERS

        assert_response :method_not_allowed
        patch "/api/v2/invoices/#{invoice.id}", params: '{}', headers: JSON_HEADERS

        assert_response :method_not_allowed
        delete "/api/v2/invoices/#{invoice.id}"

        assert_response :method_not_allowed
        post '/api/v2/plannings', params: '{}', headers: JSON_HEADERS

        assert_response :method_not_allowed
        patch "/api/v2/plannings/#{planning.id}", params: '{}', headers: JSON_HEADERS

        assert_response :method_not_allowed
        delete "/api/v2/plannings/#{planning.id}"

        assert_response :method_not_allowed
        assert Invoice.exists?(invoice.id)
      end

      # plannings

      test 'plannings are scoped to own rows and orders the user is responsible for' do
        planning = plannings(:hitobito_demo_app_planning1)
        { mark: [planning.id], pascal: [planning.id], lucien: [planning.id], long_time_john: [] }.each do |user, expected|
          login_as(user)
          get '/api/v2/plannings'

          assert_response :ok
          assert_equal expected, ids, user.to_s

          get "/api/v2/plannings/#{planning.id}"

          assert_response expected.empty? ? :not_found : :ok
        end
      end

      test 'own plannings are visible, foreign ones of other orders are not' do
        own = Planning.create!(employee: employees(:long_time_john), work_item: work_items(:hitobito_demo_app),
                               date: Date.new(2015, 3, 31), percent: 20)
        login_as(:long_time_john)

        get '/api/v2/plannings'

        assert_equal [own.id], ids
        assert_equal %w[date definitive employee_id id percent work_item_id], response.parsed_body.first.keys.sort
      end

      test 'api client sees no plannings' do
        get '/api/v2/plannings', headers: basic_auth

        assert_response :ok
        assert_empty response.parsed_body
      end

      test 'swagger spec documents the accounting routes' do
        login_as(:mark)

        get '/api/v2/swagger_doc'

        assert_response :ok
        paths = response.parsed_body['paths']

        assert_equal %w[get post], paths['/accounting_posts'].keys.sort
        assert_equal %w[delete get patch], paths['/accounting_posts/{id}'].keys.sort
        assert_includes paths.keys, '/orders/{id}/accounting_posts'
        assert_includes paths.keys, '/orders/{id}/invoices'
        assert_equal %w[get], paths['/invoices'].keys
        assert_equal %w[get], paths['/plannings'].keys
        assert_includes response.parsed_body['definitions']['AccountingPost']['properties'].keys, 'offered_rate'
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
