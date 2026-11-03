# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V2
    # Ports test/api/v2/orders_test.rb of the Grape spike.
    # mark: management, lucien: responsible of puzzletime + hitobito_demo, long_time_john: responsible of
    # webauftritt, pascal: regular employee.
    class GraphitiOrdersTest < ActionDispatch::IntegrationTest
      include GraphitiApiHelper

      # An order document with sideposted work item (and optional has_many children as {type => [attributes]}).
      def order_doc(attributes: {}, work_item: nil, id: nil, children: {})
        included = []
        relationships = {}
        sidepost = lambda do |name, type, attrs, resource_id = nil|
          temp = "#{type}-#{included.size}"
          link = { type:, method: resource_id ? 'update' : 'create' }
          link.merge!(resource_id ? { id: resource_id.to_s } : { 'temp-id': temp })
          included << { type:, attributes: attrs }.merge(resource_id ? { id: resource_id.to_s } : { 'temp-id': temp })
          relationships[name] = { data: name == :work_item ? link : (relationships.dig(name, :data) || []) << link }
        end
        sidepost.call(:work_item, 'work_items', work_item[:attributes], work_item[:id]) if work_item
        children.each { |name, rows| rows.each { |row| sidepost.call(name, name.to_s, row) } }
        { data: { type: 'orders', id: id&.to_s, attributes:, relationships: }.compact.reject { |_, v| v == {} },
          included: }.to_json
      end

      def new_order(parent: work_items(:puzzle).id, **options)
        order_doc(attributes: { kind_id: order_kinds(:mandat).id, department_id: departments(:devone).id,
                                **options.delete(:attributes).to_h },
                  work_item: { attributes: { name: 'Neuer Auftrag', shortname: 'NEWO', parent_id: parent } },
                  **options)
      end

      def api_post(path, body)
        post("/api/v2/#{path}", params: body, headers: JSONAPI)
      end

      def api_patch(path, body)
        patch("/api/v2/#{path}", params: body, headers: JSONAPI)
      end

      def api_put(path, body)
        put("/api/v2/#{path}", params: body, headers: JSONAPI)
      end

      # The attribute of the included resources of a type.
      def included_attributes(type, attribute)
        json_body['included'].select { |resource| resource['type'] == type }.pluck('attributes').pluck(attribute)
      end

      def names
        json_body['data'].map { |resource| resource.dig('attributes', 'name') }
      end

      def error_pointers
        json_body['errors'].pluck('source').pluck('pointer')
      end

      def month_doc(attribute, value)
        payload('orders', { attribute => value })
      end

      # --- orders

      test 'everybody reads orders with work item and team members' do
        order = orders(:puzzletime)
        order.order_team_members.create!(employee: employees(:pascal), comment: 'dev')

        %i[mark lucien pascal].each do |user|
          login_as(user)
          get "/api/v2/orders/#{order.id}", params: { include: 'work_item,order_team_members' }, headers: JSONAPI

          assert_response :ok, user.to_s
          assert_equal 'PuzzleTime', json_body.dig('data', 'attributes', 'name')
          assert_equal %w[PuzzleTime], included_attributes('work_items', 'name')
          assert_equal [employees(:pascal).id], included_attributes('order_team_members', 'employee_id')
        end

        login_as(:pascal)

        assert_equal Order.pluck(:id).sort, ids('/api/v2/orders').sort
      end

      test 'the api client reads orders but not clients' do
        get '/api/v2/orders', headers: JSONAPI.merge(basic_auth)

        assert_response :ok
        get '/api/v2/clients', headers: JSONAPI.merge(basic_auth)

        assert_response :forbidden
      end

      test 'orders filter and sort without extra code' do
        login_as(:mark)

        assert_equal [orders(:hitobito_demo).id, orders(:puzzletime).id].sort,
                     ids('/api/v2/orders', filter: { responsible_id: employees(:lucien).id }).sort
      end

      test 'management creates an order with sideposted work item, team and contacts under a client' do
        login_as(:mark)
        assert_difference(['Order.count', 'WorkItem.count']) do
          api_post 'orders', new_order(attributes: { responsible_id: employees(:lucien).id },
                                       children: { order_team_members: [{ employee_id: employees(:pascal).id,
                                                                          comment: 'dev' }],
                                                   additional_crm_orders: [{ crm_key: 'CRM-9' }] })
        end

        assert_response :created
        order = Order.find(json_body.dig('data', 'id'))

        assert_equal work_items(:puzzle).id, order.work_item.parent_id
        assert_equal [employees(:pascal)], order.team_members
        assert_equal ['CRM-9'], order.additional_crm_orders.pluck(:crm_key)
        assert_equal TargetScope.count, order.targets.count
        assert_equal [order.work_item.name, 'NEWO'], [json_body.dig('data', 'attributes', 'name'),
                                                      json_body.dig('data', 'attributes', 'shortname')]
      end

      test 'sideposted contacts must belong to the client of the order' do
        login_as(:mark)
        own = contacts(:puzzle_rava)
        foreign = Contact.find_by!(client_id: clients(:swisstopo).id)

        assert_no_difference('Order.count') do
          api_post 'orders', new_order(children: { order_contacts: [{ contact_id: foreign.id }] })
        end
        assert_response :unprocessable_content

        login_as(:mark)

        assert_difference('OrderContact.count') do
          api_post 'orders', new_order(children: { order_contacts: [{ contact_id: own.id, comment: 'main' }] })
        end
        assert_response :created
        assert_equal [own], Order.find(json_body.dig('data', 'id')).contacts
      end

      test 'invoices and accounting posts are listed per order through the scope of their own resource' do
        order = orders(:webauftritt)

        login_as(:mark)

        assert_equal [invoices(:webauftritt_may).id], ids("/api/v2/orders/#{order.id}/invoices")

        login_as(:mark)

        assert_equal [accounting_posts(:webauftritt).id], ids("/api/v2/orders/#{order.id}/accounting_posts")

        login_as(:pascal)

        assert_empty ids("/api/v2/orders/#{order.id}/invoices")
      end

      test 'the contract is an include' do
        login_as(:pascal)
        get "/api/v2/orders/#{orders(:puzzletime).id}", params: { include: 'contract' }, headers: JSONAPI

        assert_equal 'asdf1234', json_body['included'].first.dig('attributes', 'number')
      end

      test 'order must be created below a client or a client category' do
        login_as(:mark)

        [work_items(:puzzletime).id, 999_999, nil].each do |parent_id|
          assert_no_difference(['Order.count', 'WorkItem.count']) do
            api_post 'orders', new_order(parent: parent_id)
          end
          assert_response :unprocessable_content, parent_id.to_s
          assert_includes error_pointers.join, 'parent_id' if parent_id
        end
      end

      test 'responsible creates with HTML defaults but cannot hand the order to someone else' do
        login_as(:lucien)

        api_post 'orders', new_order

        assert_response :created
        assert_equal employees(:lucien).id, json_body.dig('data', 'attributes', 'responsible_id')
        assert_equal departments(:devone).id, json_body.dig('data', 'attributes', 'department_id')

        login_as(:lucien)

        assert_no_difference(['Order.count', 'WorkItem.count']) do
          api_post 'orders', new_order(attributes: { responsible_id: employees(:mark).id })
        end
        assert_response :forbidden
      end

      test 'regular employees cannot create or update orders' do
        login_as(:pascal)

        assert_no_difference(['Order.count', 'WorkItem.count']) { api_post 'orders', new_order }
        assert_response :forbidden

        login_as(:pascal)
        api_patch "orders/#{orders(:puzzletime).id}", payload('orders', { crm_key: 'x' }, orders(:puzzletime).id)

        assert_response :forbidden
      end

      test 'responsible updates only own orders and cannot reassign or move them' do
        login_as(:lucien)
        order = orders(:puzzletime)
        item = order.work_item
        doc = order_doc(attributes: { crm_key: 'CRM-1' }, id: order.id,
                        work_item: { id: item.id, attributes: { description: 'neu' } })

        api_patch "orders/#{order.id}", doc

        assert_response :ok
        assert_equal 'CRM-1', order.reload.crm_key
        assert_equal 'neu', order.work_item.description

        login_as(:lucien)
        api_patch "orders/#{order.id}", payload('orders', { responsible_id: employees(:mark).id }, order.id)

        assert_response :forbidden
        assert_equal employees(:lucien).id, order.reload.responsible_id

        login_as(:lucien)
        api_patch "orders/#{order.id}",
                  order_doc(id: order.id, work_item: { id: item.id, attributes: { parent_id: work_items(:swisstopo).id } })

        assert_response :unprocessable_content
        assert_equal work_items(:puzzle).id, item.reload.parent_id

        login_as(:lucien)
        api_patch "orders/#{orders(:webauftritt).id}",
                  payload('orders', { crm_key: 'nope' }, orders(:webauftritt).id)

        assert_response :forbidden
      end

      test 'a responsible cannot take over the order of somebody else' do
        login_as(:lucien)
        order = orders(:webauftritt)

        api_patch "orders/#{order.id}", payload('orders', { responsible_id: employees(:lucien).id }, order.id)

        assert_response :forbidden
        assert_equal employees(:long_time_john).id, order.reload.responsible_id
      end

      test 'a work item cannot be exchanged by a sidepost' do
        login_as(:mark)
        order = orders(:puzzletime)

        api_patch "orders/#{order.id}",
                  order_doc(id: order.id, work_item: { id: orders(:allgemein).work_item_id, attributes: {} })

        assert_response :unprocessable_content
        assert_not_equal orders(:allgemein).work_item_id, order.reload.work_item_id
      end

      test 'management reassigns the responsible and validation errors render as 422' do
        login_as(:mark)
        order = orders(:puzzletime)

        api_patch "orders/#{order.id}", payload('orders', { responsible_id: employees(:mark).id }, order.id)

        assert_response :ok
        assert_equal employees(:mark).id, order.reload.responsible_id

        api_patch "orders/#{order.id}",
                  order_doc(id: order.id, work_item: { id: order.work_item_id, attributes: { name: '' } })

        assert_response :unprocessable_content
        assert_match(/name/, json_body['errors'].to_json)
      end

      test 'team members are updated and removed by sidepost' do
        login_as(:mark)
        order = orders(:puzzletime)
        member = order.order_team_members.create!(employee: employees(:pascal), comment: 'dev')
        doc = { data: { type: 'orders', id: order.id.to_s,
                        relationships: { order_team_members: { data: [{ type: 'order_team_members', id: member.id.to_s,
                                                                        method: 'update' }] } } },
                included: [{ type: 'order_team_members', id: member.id.to_s, attributes: { comment: 'lead' } }] }

        api_patch "orders/#{order.id}", doc.to_json

        assert_response :ok
        assert_equal 'lead', member.reload.comment

        login_as(:mark)
        doc[:data][:relationships][:order_team_members][:data][0][:method] = 'destroy'
        api_patch "orders/#{order.id}", doc.to_json

        assert_response :ok
        assert_not OrderTeamMember.exists?(member.id)
      end

      test 'responsibles of other orders cannot write team members' do
        login_as(:long_time_john)
        order = orders(:puzzletime)

        assert_no_difference('OrderTeamMember.count') do
          api_patch "orders/#{order.id}",
                    order_doc(id: order.id, children: { order_team_members: [{ employee_id: employees(:pascal).id }] })
        end
        assert_response :forbidden
      end

      test 'completed_at and committed_at are not plain order attributes' do
        login_as(:mark)
        order = orders(:puzzletime)

        api_patch "orders/#{order.id}",
                  payload('orders', { completed_at: Time.zone.today.end_of_month.to_s }, order.id)

        assert_response :bad_request
        assert_nil order.reload.completed_at
      end

      test 'completed follows the month rules and ability' do
        order = orders(:puzzletime)
        this_month = Time.zone.today.end_of_month
        last_month = (Time.zone.today - 1.month).end_of_month

        login_as(:lucien)
        api_patch "orders/#{order.id}/completed", month_doc(:completed_at, last_month.to_s)

        assert_response :ok
        assert_equal last_month, order.reload.completed_at
        assert_equal last_month.to_s, json_body.dig('data', 'attributes', 'completed_at')

        login_as(:lucien)
        api_patch "orders/#{order.id}/completed", month_doc(:completed_at, (this_month - 3.months).end_of_month.to_s)

        assert_response :unprocessable_content
        assert_includes error_pointers, '/data/attributes/completed_at'

        login_as(:lucien)
        api_patch "orders/#{order.id}/completed", month_doc(:completed_at, nil)

        assert_response :unprocessable_content

        login_as(:pascal)
        api_patch "orders/#{order.id}/completed", month_doc(:completed_at, this_month.to_s)

        assert_response :forbidden

        login_as(:mark)
        api_patch "orders/#{order.id}/completed", month_doc(:completed_at, nil)

        assert_response :ok
        assert_nil order.reload.completed_at
      end

      test 'committed is not allowed for responsibles' do
        order = orders(:puzzletime)
        month = Time.zone.today.end_of_month

        login_as(:lucien)
        api_patch "orders/#{order.id}/committed", month_doc(:committed_at, month.to_s)

        assert_response :forbidden

        login_as(:mark)
        api_patch "orders/#{order.id}/committed", month_doc(:committed_at, month.to_s)

        assert_response :ok
        assert_equal month, order.reload.committed_at
      end

      test 'orders with worktimes cannot be deleted' do
        login_as(:mark)
        order = orders(:puzzletime)

        assert_no_difference('Order.count') { delete "/api/v2/orders/#{order.id}", headers: JSONAPI }
        assert_response :unprocessable_content
      end

      # --- clients

      test 'management and responsibles write clients, regular employees see nothing' do
        login_as(:mark)
        doc = { data: { type: 'clients', attributes: { allow_local: true },
                        relationships: { work_item: { data: { type: 'work_items', 'temp-id': 'w', method: 'create' } } } },
                included: [{ type: 'work_items', 'temp-id': 'w', attributes: { name: 'Neukunde', shortname: 'NK' } }] }

        assert_difference(['Client.count', 'WorkItem.count']) { api_post 'clients', doc.to_json }

        assert_response :created
        client = Client.find(json_body.dig('data', 'id'))

        assert_nil client.work_item.parent_id
        assert_equal 'Neukunde', json_body.dig('data', 'attributes', 'name')

        login_as(:lucien)
        api_patch "clients/#{client.id}",
                  { data: { type: 'clients', id: client.id.to_s, attributes: { crm_key: '4711' },
                            relationships: { work_item: { data: { type: 'work_items', id: client.work_item_id.to_s,
                                                                  method: 'update' } } } },
                    included: [{ type: 'work_items', id: client.work_item_id.to_s,
                                 attributes: { description: 'd' } }] }.to_json

        assert_response :ok
        assert_equal %w[4711 d], [client.reload.crm_key, client.work_item.description]

        login_as(:pascal)
        get '/api/v2/clients', headers: JSONAPI

        assert_response :forbidden
        login_as(:pascal)
        api_patch "clients/#{client.id}", payload('clients', { crm_key: 'x' }, client.id)

        assert_response :not_found
      end

      test 'a client work item cannot get a parent' do
        login_as(:mark)
        doc = { data: { type: 'clients', attributes: {},
                        relationships: { work_item: { data: { type: 'work_items', 'temp-id': 'w', method: 'create' } } } },
                included: [{ type: 'work_items', 'temp-id': 'w',
                             attributes: { name: 'Neukunde', shortname: 'NK', parent_id: work_items(:puzzle).id } }] }

        assert_no_difference(['Client.count', 'WorkItem.count']) { api_post 'clients', doc.to_json }
        assert_response :unprocessable_content
      end

      # --- comments

      test 'comments: anybody creates, only the creator updates, nobody deletes' do
        order = orders(:puzzletime)

        login_as(:pascal)
        api_post 'order_comments', payload('order_comments', { order_id: order.id, text: 'hello' })

        assert_response :created
        comment = OrderComment.find(json_body.dig('data', 'id'))

        assert_equal employees(:pascal), comment.creator
        assert_equal employees(:pascal), comment.updater

        # regular employees may comment but, like in the UI, never edit
        login_as(:pascal)
        api_patch "order_comments/#{comment.id}", payload('order_comments', { text: 'edited' }, comment.id)

        assert_response :forbidden

        comment.update_columns(creator_id: employees(:lucien).id)

        login_as(:mark)
        api_patch "order_comments/#{comment.id}", payload('order_comments', { text: 'hijacked' }, comment.id)

        assert_response :forbidden
        assert_equal 'hello', comment.reload.text

        login_as(:lucien)
        api_patch "order_comments/#{comment.id}", payload('order_comments', { text: 'edited' }, comment.id)

        assert_response :ok
        assert_equal employees(:lucien), comment.reload.updater

        login_as(:lucien)
        api_patch "order_comments/#{comment.id}",
                  payload('order_comments', { order_id: orders(:allgemein).id }, comment.id)

        assert_response :bad_request
        assert_equal order.id, comment.reload.order_id

        # no routes: nobody deletes, and there is no index (comments are listed per order)
        assert_raises(ActionController::RoutingError) { delete "/api/v2/order_comments/#{comment.id}", headers: JSONAPI }
        assert_raises(ActionController::RoutingError) { get '/api/v2/order_comments', headers: JSONAPI }
      end

      test 'the api client cannot comment' do
        assert_no_difference('OrderComment.count') do
          post '/api/v2/order_comments', params: payload('order_comments', { order_id: orders(:puzzletime).id,
                                                                             text: 'hello' }),
                                         headers: JSONAPI.merge(basic_auth)
        end
        assert_response :forbidden
      end

      test 'comments are listed per order' do
        login_as(:pascal)
        get "/api/v2/orders/#{orders(:puzzletime).id}/comments", headers: JSONAPI

        assert_response :ok
        assert_equal 2, json_body['data'].size

        login_as(:pascal)

        assert_empty ids("/api/v2/orders/#{orders(:allgemein).id}/comments")

        login_as(:pascal)
        get "/api/v2/orders/#{orders(:puzzletime).id}", params: { include: 'comments' }, headers: JSONAPI

        assert_equal 2, json_body['included'].size
      end

      # --- risks and chances

      def risk_doc(type, order, **attributes)
        payload(type, { order_id: order.id, name: 'Flood', probability: 'high', impact: 'high', measure: 'boat',
                        **attributes })
      end

      test 'risk writes update the major risk value of the order' do
        login_as(:lucien)
        order = orders(:puzzletime)

        api_post 'order_risks', risk_doc('order_risks', order)

        assert_response :created
        assert_equal 16, order.reload.major_risk_value
        id = json_body.dig('data', 'id')

        login_as(:lucien)
        api_patch "order_risks/#{id}", payload('order_risks', { impact: 'low' }, id)

        assert_response :ok
        assert_equal 8, order.reload.major_risk_value

        login_as(:lucien)
        delete "/api/v2/order_risks/#{id}", headers: JSONAPI

        assert_response :ok
        assert_equal 3, order.reload.major_risk_value
      end

      test 'chances update the major chance value and are listed per order' do
        login_as(:mark)
        order = orders(:puzzletime)

        api_post 'order_chances', risk_doc('order_chances', order, name: 'Win')

        assert_response :created
        assert_equal 16, order.reload.major_chance_value

        login_as(:mark)
        get "/api/v2/orders/#{order.id}/order_chances", headers: JSONAPI

        assert_equal ['Win', 'World domination'], names.sort

        get "/api/v2/orders/#{order.id}/order_risks", headers: JSONAPI

        assert_equal ['Atomic desaster'], names

        get "/api/v2/orders/#{order.id}/order_uncertainties", headers: JSONAPI

        assert_equal 3, json_body['data'].size
      end

      test 'an invalid order surfaces as 422 and rolls the risk back' do
        login_as(:mark)
        order = orders(:puzzletime)
        order.update_column(:kind_id, nil)

        assert_no_difference('OrderRisk.count') do
          api_post 'order_risks', risk_doc('order_risks', order, name: 'Fire', probability: 'low', impact: 'low')
        end
        assert_response :unprocessable_content
        assert_match(/order\.kind_id/, error_pointers.join)
      end

      test 'risk writes follow order responsibility' do
        order = orders(:webauftritt)

        %i[lucien pascal].each do |user|
          login_as(user)

          assert_no_difference('OrderRisk.count') { api_post 'order_risks', risk_doc('order_risks', order) }
          assert_response :forbidden, user.to_s
        end

        login_as(:long_time_john)

        assert_difference('OrderRisk.count') { api_post 'order_risks', risk_doc('order_risks', order) }

        login_as(:pascal)

        assert_equal OrderUncertainty.pluck(:id).sort, ids('/api/v2/order_uncertainties').sort
        login_as(:pascal)
        assert_raises(ActionController::RoutingError) do
          post '/api/v2/order_uncertainties', params: risk_doc('order_uncertainties', order), headers: JSONAPI
        end
      end

      test 'risk order cannot be changed after creation' do
        login_as(:mark)
        risk = order_uncertainties(:atomic_desaster)

        api_patch "order_risks/#{risk.id}", payload('order_risks', { order_id: orders(:allgemein).id }, risk.id)

        assert_response :bad_request
        assert_equal orders(:puzzletime).id, risk.reload.order_id
      end

      # --- targets

      test 'everybody lists targets of an order' do
        login_as(:pascal)
        get "/api/v2/orders/#{orders(:puzzletime).id}/targets", headers: JSONAPI

        assert_response :ok
        assert_equal %w[green green orange], json_body['data'].map { |doc| doc.dig('attributes', 'rating') }.sort
        assert_equal %w[comment order_id rating target_scope_id],
                     json_body['data'].first['attributes'].keys.sort
      end

      def targets_doc(*targets)
        { data: targets.map { |id, attributes| { type: 'order_targets', id: id.to_s, attributes: } } }.to_json
      end

      test 'responsible bulk updates targets through the order ability' do
        login_as(:lucien)
        order = orders(:puzzletime)
        time = order_targets(:puzzletime_time)
        cost = order_targets(:puzzletime_cost)

        api_patch "orders/#{order.id}/targets",
                  targets_doc([time.id, { rating: 'red', comment: 'late' }], [cost.id, { rating: 'green' }])

        assert_response :ok
        assert_equal %w[red late], time.reload.slice(:rating, :comment).values
        assert_equal 'green', cost.reload.rating
        assert_equal 3, json_body['data'].size
      end

      test 'target updates are all or nothing with per-target errors' do
        login_as(:mark)
        order = orders(:puzzletime)
        time = order_targets(:puzzletime_time)
        quality = order_targets(:puzzletime_quality)

        api_patch "orders/#{order.id}/targets",
                  targets_doc([time.id, { rating: 'green', comment: 'ok' }], [quality.id, { rating: 'red' }])

        assert_response :unprocessable_content
        assert_equal ['/data/1/attributes/comment'], error_pointers
        assert_equal 'green', quality.reload.rating
        assert_nil time.reload.comment
      end

      test 'targets of other orders are not found and others may not update' do
        order = orders(:puzzletime)

        login_as(:mark)
        api_patch "orders/#{order.id}/targets", targets_doc([order_targets(:allgemein_time).id, { rating: 'green' }])

        assert_response :not_found

        %i[pascal long_time_john].each do |user|
          login_as(user)
          api_patch "orders/#{order.id}/targets", targets_doc([order_targets(:puzzletime_time).id, { rating: 'red' }])

          assert_response :forbidden, user.to_s
        end
        assert_equal 'green', order_targets(:puzzletime_time).rating
      end

      # --- contract

      test 'everybody reads the contract, 404 without one' do
        login_as(:pascal)
        get "/api/v2/orders/#{orders(:puzzletime).id}/contract", headers: JSONAPI

        assert_response :ok
        assert_equal 'asdf1234', json_body.dig('data', 'attributes', 'number')

        login_as(:pascal)
        get "/api/v2/orders/#{orders(:allgemein).id}/contract", headers: JSONAPI

        assert_response :not_found
      end

      test 'contract upsert is limited to management and the responsible' do
        order = orders(:hitobito_demo)
        contract = payload('contracts', { number: 'C-1', start_date: '2026-01-01', end_date: '2026-12-31',
                                          payment_period: 30 })

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
        api_put "orders/#{order.id}/contract", payload('contracts', { number: 'C-2' })

        assert_response :ok
        assert_equal ['C-2', 30], order.reload.contract.slice(:number, :payment_period).values
        assert_equal 1, Contract.where(number: %w[C-1 C-2]).count
      end

      test 'invalid contracts are 422' do
        login_as(:mark)
        api_put "orders/#{orders(:hitobito_demo).id}/contract", payload('contracts', { number: 'C-1', payment_period: 7 })

        assert_response :unprocessable_content
        assert_includes error_pointers, '/data/attributes/payment_period'
      end
    end
  end
end
