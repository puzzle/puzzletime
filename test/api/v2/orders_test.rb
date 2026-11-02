# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V2
    # mark: management, lucien: responsible of puzzletime + hitobito_demo, long_time_john: responsible of
    # webauftritt, pascal: regular employee.
    class OrdersTest < ActionDispatch::IntegrationTest
      JSON_HEADERS = { 'CONTENT_TYPE' => 'application/json' }.freeze

      def api_post(path, body)
        post("/api/v2/#{path}", params: body.to_json, headers: JSON_HEADERS)
      end

      def api_patch(path, body)
        patch("/api/v2/#{path}", params: body.to_json, headers: JSON_HEADERS)
      end

      def api_put(path, body)
        put("/api/v2/#{path}", params: body.to_json, headers: JSON_HEADERS)
      end

      def new_order(extra = {})
        { work_item_attributes: { name: 'Neuer Auftrag', shortname: 'NEWO', parent_id: work_items(:puzzle).id },
          kind_id: order_kinds(:mandat).id, department_id: departments(:devone).id }.merge(extra)
      end

      # --- orders

      test 'everybody reads orders with nested work item and team' do
        order = orders(:puzzletime)
        order.order_team_members.create!(employee: employees(:pascal), comment: 'dev')

        %i[mark lucien pascal].each do |user|
          login_as(user)
          get "/api/v2/orders/#{order.id}"

          assert_response :ok, user.to_s
          assert_equal 'PuzzleTime', response.parsed_body.dig('work_item', 'name')
          assert_equal [employees(:pascal).id], response.parsed_body['order_team_members'].pluck('employee_id')
        end

        get '/api/v2/orders'

        assert_response :ok
        assert_equal Order.count, response.parsed_body.size
      end

      test 'management creates an order with nested work item, team and contacts under a client' do
        login_as(:mark)

        assert_difference(['Order.count', 'WorkItem.count']) do
          api_post 'orders', new_order(responsible_id: employees(:lucien).id,
                                       order_team_members_attributes: [{ employee_id: employees(:pascal).id }])
        end

        assert_response :created
        order = Order.find(response.parsed_body['id'])

        assert_equal work_items(:puzzle).id, order.work_item.parent_id
        assert_equal [employees(:pascal)], order.team_members
        assert_equal TargetScope.count, order.targets.count
        assert_equal order.work_item.id, response.parsed_body.dig('work_item', 'id')
      end

      test 'order must be created below a client or a client category' do
        login_as(:mark)

        [work_items(:puzzletime).id, 999_999].each do |parent_id|
          assert_no_difference('Order.count') do
            api_post 'orders', new_order(work_item_attributes: { name: 'X', shortname: 'XX', parent_id: })
          end
          assert_response :unprocessable_content
          assert_includes response.parsed_body['errors'].keys, 'work_item.parent_id'
        end

        assert_no_difference('Order.count') do
          api_post 'orders', new_order(work_item_attributes: { name: 'X', shortname: 'XX' })
        end
        assert_response :unprocessable_content
      end

      test 'responsible creates with HTML defaults but cannot hand the order to someone else' do
        login_as(:lucien)
        lucien = employees(:lucien)

        api_post 'orders', new_order

        assert_response :created
        assert_equal lucien.id, response.parsed_body['responsible_id']

        assert_no_difference('Order.count') do
          api_post 'orders', new_order(responsible_id: employees(:mark).id,
                                       work_item_attributes: { name: 'Anderer', shortname: 'ANDR',
                                                               parent_id: work_items(:puzzle).id })
        end
        assert_response :forbidden
      end

      test 'regular employees cannot create or update orders' do
        login_as(:pascal)

        assert_no_difference('Order.count') { api_post 'orders', new_order }
        assert_response :forbidden

        api_patch "orders/#{orders(:puzzletime).id}", crm_key: 'x'

        assert_response :forbidden
      end

      test 'responsible updates only own orders and cannot reassign or move them' do
        login_as(:lucien)
        order = orders(:puzzletime)

        api_patch "orders/#{order.id}", crm_key: 'CRM-1', work_item_attributes: { description: 'neu' }

        assert_response :ok
        assert_equal 'CRM-1', order.reload.crm_key
        assert_equal 'neu', order.work_item.description

        api_patch "orders/#{order.id}", responsible_id: employees(:mark).id

        assert_response :forbidden
        assert_equal employees(:lucien).id, order.reload.responsible_id

        api_patch "orders/#{order.id}", work_item_attributes: { parent_id: work_items(:swisstopo).id }

        assert_response :unprocessable_content
        assert_equal work_items(:puzzle).id, order.work_item.reload.parent_id

        api_patch "orders/#{orders(:webauftritt).id}", crm_key: 'nope'

        assert_response :forbidden
      end

      test 'management reassigns the responsible and validation errors render as 422' do
        login_as(:mark)
        order = orders(:puzzletime)

        api_patch "orders/#{order.id}", responsible_id: employees(:mark).id

        assert_response :ok
        assert_equal employees(:mark).id, order.reload.responsible_id

        api_patch "orders/#{order.id}", work_item_attributes: { name: '' }

        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'work_item.name'
      end

      test 'completed_at and committed_at are not plain order attributes' do
        login_as(:mark)
        order = orders(:puzzletime)

        api_patch "orders/#{order.id}", completed_at: Time.zone.today.end_of_month.to_s

        assert_response :ok
        assert_nil order.reload.completed_at
      end

      test 'completed follows the month rules and ability' do
        order = orders(:puzzletime)
        this_month = Time.zone.today.end_of_month
        last_month = (Time.zone.today - 1.month).end_of_month

        login_as(:lucien)
        api_patch "orders/#{order.id}/completed", completed_at: last_month.to_s

        assert_response :ok
        assert_equal last_month, order.reload.completed_at

        api_patch "orders/#{order.id}/completed", completed_at: (this_month - 3.months).end_of_month.to_s

        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'completed_at'

        api_patch "orders/#{order.id}/completed", completed_at: nil

        assert_response :unprocessable_content

        login_as(:pascal)
        api_patch "orders/#{order.id}/completed", completed_at: this_month.to_s

        assert_response :forbidden

        login_as(:mark)
        api_patch "orders/#{order.id}/completed", completed_at: nil

        assert_response :ok
        assert_nil order.reload.completed_at
      end

      test 'committed is not allowed for responsibles' do
        order = orders(:puzzletime)
        month = Time.zone.today.end_of_month

        login_as(:lucien)
        api_patch "orders/#{order.id}/committed", committed_at: month.to_s

        assert_response :forbidden

        login_as(:mark)
        api_patch "orders/#{order.id}/committed", committed_at: month.to_s

        assert_response :ok
        assert_equal month, order.reload.committed_at
      end

      test 'orders with worktimes cannot be deleted' do
        login_as(:mark)
        order = orders(:puzzletime)

        assert_no_difference('Order.count') { delete "/api/v2/orders/#{order.id}" }
        assert_response :unprocessable_content
      end

      # --- clients

      test 'management and responsibles write clients, regular employees see nothing' do
        login_as(:mark)

        assert_difference(['Client.count', 'WorkItem.count']) do
          api_post 'clients', work_item_attributes: { name: 'Neukunde', shortname: 'NK' }, allow_local: true
        end
        assert_response :created
        client = Client.find(response.parsed_body['id'])

        assert_nil client.work_item.parent_id
        assert_equal 'Neukunde', response.parsed_body['name']

        login_as(:lucien)
        api_patch "clients/#{client.id}", crm_key: '4711', work_item_attributes: { description: 'd' }

        assert_response :ok
        assert_equal %w[4711 d], [client.reload.crm_key, client.work_item.description]

        login_as(:pascal)
        get '/api/v2/clients'

        assert_response :forbidden
        api_patch "clients/#{client.id}", crm_key: 'x'

        assert_response :not_found
      end

      test 'api client sees no clients' do
        get '/api/v2/clients', headers: { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(
          Settings.api_client.user, Settings.api_client.password
        ) }

        assert_response :forbidden
      end

      # --- comments

      test 'comments: anybody creates, only the creator updates, nobody deletes' do
        order = orders(:puzzletime)

        login_as(:pascal)
        api_post 'order_comments', order_id: order.id, text: 'hello'

        assert_response :created
        comment = OrderComment.find(response.parsed_body['id'])

        assert_equal employees(:pascal), comment.creator
        assert_equal employees(:pascal), comment.updater

        # regular employees may comment but, like in the UI, never edit
        api_patch "order_comments/#{comment.id}", text: 'edited'

        assert_response :forbidden

        comment.update_columns(creator_id: employees(:lucien).id)

        login_as(:mark)
        api_patch "order_comments/#{comment.id}", text: 'hijacked'

        assert_response :forbidden
        assert_equal 'hello', comment.reload.text

        login_as(:lucien)
        api_patch "order_comments/#{comment.id}", text: 'edited', order_id: orders(:allgemein).id

        assert_response :ok
        assert_equal ['edited', order.id], [comment.reload.text, comment.order_id]

        assert_no_difference('OrderComment.count') { delete "/api/v2/order_comments/#{comment.id}" }
        assert_not response.successful?
        get '/api/v2/order_comments'

        assert_not response.successful?
      end

      test 'comments are listed per order' do
        login_as(:pascal)
        get "/api/v2/orders/#{orders(:puzzletime).id}/comments"

        assert_response :ok
        assert_equal 2, response.parsed_body.size
        get "/api/v2/orders/#{orders(:allgemein).id}/comments"

        assert_empty response.parsed_body
      end

      # --- risks and chances

      test 'risk writes update the major risk value of the order' do
        login_as(:lucien)
        order = orders(:puzzletime)

        api_post 'order_risks', order_id: order.id, name: 'Flood', probability: 'high', impact: 'high', measure: 'boat'

        assert_response :created
        assert_equal 16, order.reload.major_risk_value
        id = response.parsed_body['id']

        api_patch "order_risks/#{id}", impact: 'low'

        assert_response :ok
        assert_equal 8, order.reload.major_risk_value

        delete "/api/v2/order_risks/#{id}"

        assert_response :no_content
        assert_equal 3, order.reload.major_risk_value
      end

      test 'chances update the major chance value and are listed per order' do
        login_as(:mark)
        order = orders(:puzzletime)

        api_post 'order_chances', order_id: order.id, name: 'Win', probability: 'high', impact: 'high', measure: 'm'

        assert_response :created
        assert_equal 16, order.reload.major_chance_value
        get "/api/v2/orders/#{order.id}/order_chances"

        assert_equal ['Win', 'World domination'], response.parsed_body.pluck('name').sort
        get "/api/v2/orders/#{order.id}/order_risks"

        assert_equal ['Atomic desaster'], response.parsed_body.pluck('name')
        get "/api/v2/orders/#{order.id}/order_uncertainties"

        assert_equal 3, response.parsed_body.size
      end

      test 'an invalid order surfaces as 422 and rolls the risk back' do
        login_as(:mark)
        order = orders(:puzzletime)
        order.update_column(:kind_id, nil)

        assert_no_difference('OrderRisk.count') do
          api_post 'order_risks', order_id: order.id, name: 'Fire', probability: 'low', impact: 'low', measure: 'm'
        end
        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'order.kind_id'
      end

      test 'risk writes follow order responsibility' do
        order = orders(:webauftritt)
        attrs = { order_id: order.id, name: 'Fire', probability: 'low', impact: 'low', measure: 'm' }

        %i[lucien pascal].each do |user|
          login_as(user)

          assert_no_difference('OrderRisk.count') { api_post 'order_risks', attrs }
          assert_response :forbidden, user.to_s
        end

        login_as(:long_time_john)

        assert_difference('OrderRisk.count') { api_post 'order_risks', attrs }

        login_as(:pascal)
        get '/api/v2/order_uncertainties'

        assert_response :ok
        api_post 'order_uncertainties', attrs

        assert_not response.successful?
      end

      test 'risk order cannot be changed after creation' do
        login_as(:mark)
        risk = order_uncertainties(:atomic_desaster)

        api_patch "order_risks/#{risk.id}", order_id: orders(:allgemein).id

        assert_equal orders(:puzzletime).id, risk.reload.order_id
      end

      # --- targets

      test 'everybody lists targets of an order' do
        login_as(:pascal)
        get "/api/v2/orders/#{orders(:puzzletime).id}/targets"

        assert_response :ok
        assert_equal %w[green green orange], response.parsed_body.pluck('rating').sort
        assert_equal %w[comment id order_id rating target_scope_id], response.parsed_body.first.keys.sort
      end

      test 'responsible bulk updates targets through the order ability' do
        login_as(:lucien)
        order = orders(:puzzletime)
        time = order_targets(:puzzletime_time)
        cost = order_targets(:puzzletime_cost)

        api_patch "orders/#{order.id}/targets",
                  targets: [{ id: time.id, rating: 'red', comment: 'late' }, { id: cost.id, rating: 'green' }]

        assert_response :ok
        assert_equal %w[red late], time.reload.slice(:rating, :comment).values
        assert_equal 'green', cost.reload.rating
        assert_equal 3, response.parsed_body.size
      end

      test 'target updates are all or nothing with per-target errors' do
        login_as(:mark)
        order = orders(:puzzletime)
        time = order_targets(:puzzletime_time)
        quality = order_targets(:puzzletime_quality)

        api_patch "orders/#{order.id}/targets",
                  targets: [{ id: time.id, rating: 'green', comment: 'ok' },
                            { id: quality.id, rating: 'red' }]

        assert_response :unprocessable_content
        assert_equal ["targets.#{quality.id}.comment"], response.parsed_body['errors'].keys
        assert_equal 'green', quality.reload.rating
        assert_nil time.reload.comment
      end

      test 'targets of other orders are not found and others may not update' do
        order = orders(:puzzletime)

        login_as(:mark)
        api_patch "orders/#{order.id}/targets", targets: [{ id: order_targets(:allgemein_time).id, rating: 'green' }]

        assert_response :not_found

        %i[pascal long_time_john].each do |user|
          login_as(user)
          api_patch "orders/#{order.id}/targets", targets: [{ id: order_targets(:puzzletime_time).id, rating: 'red' }]

          assert_response :forbidden, user.to_s
        end
        assert_equal 'green', order_targets(:puzzletime_time).rating
      end

      # --- contract

      test 'everybody reads the contract, 404 without one' do
        login_as(:pascal)
        get "/api/v2/orders/#{orders(:puzzletime).id}/contract"

        assert_response :ok
        assert_equal 'asdf1234', response.parsed_body['number']

        get "/api/v2/orders/#{orders(:allgemein).id}/contract"

        assert_response :not_found
      end

      test 'contract upsert is limited to management and the responsible' do
        order = orders(:hitobito_demo)
        contract = { number: 'C-1', start_date: '2026-01-01', end_date: '2026-12-31', payment_period: 30 }

        %i[pascal long_time_john].each do |user|
          login_as(user)
          api_put "orders/#{order.id}/contract", contract

          assert_response :forbidden, user.to_s
        end
        assert_nil order.reload.contract

        login_as(:lucien)
        api_put "orders/#{order.id}/contract", contract

        assert_response :ok
        assert_equal 'C-1', order.reload.contract.number

        login_as(:mark)
        api_put "orders/#{order.id}/contract", number: 'C-2'

        assert_response :ok
        assert_equal ['C-2', 30], order.reload.contract.slice(:number, :payment_period).values
        assert_equal 1, Contract.where(number: %w[C-1 C-2]).count
      end

      test 'invalid contracts are 422' do
        login_as(:mark)
        api_put "orders/#{orders(:hitobito_demo).id}/contract", number: 'C-1', payment_period: 7

        assert_response :unprocessable_content
        assert_includes response.parsed_body['errors'].keys, 'payment_period'
      end

      # --- docs

      test 'swagger spec documents the order routes' do
        login_as(:mark)
        get '/api/v2/swagger_doc'

        assert_response :ok
        paths = response.parsed_body['paths']

        %w[/orders /orders/{id}/completed /orders/{id}/committed /orders/{id}/targets /orders/{id}/contract
           /orders/{id}/comments /orders/{id}/order_risks /order_comments /order_risks /order_chances /clients].each do |path|
          assert_includes paths.keys, path
        end
        assert_not paths.key?('/order_targets')
        assert_includes response.parsed_body['definitions'].keys, 'Order'
      end
    end
  end
end
