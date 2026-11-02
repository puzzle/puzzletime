# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    module Resources
      # Orders and everything hanging off them (comments, risks/chances, targets, contract) plus Client writes.
      #
      # Rules mirror OrdersController, ClientsController, OrderCommentsController, OrderUncertaintiesController,
      # OrderTargetsController, ContractsController and Orders::{Completed,Committed}Controller. Deliberately not
      # exposed: order copy (`copy_id`), `crm_load`, `search`, `employees`, and plain `completed_at`/`committed_at`
      # writes on PATCH /orders/:id (they have their own month rules, see the dedicated routes).
      module Orders
        ORDER_READ = [
          :id, :crm_key, :kind_id, :department_id, :responsible_id, :status_id, :contract_id, :billing_address_id,
          :work_item_id, :completed_at, :committed_at, :closed_at, :major_risk_value, :major_chance_value,
          { work_item: %i[id parent_id name shortname description path_names path_shortnames],
            order_team_members: %i[id employee_id comment],
            order_contacts: %i[id contact_id comment],
            additional_crm_orders: %i[id crm_key name] }
        ].freeze

        UNCERTAINTY_READ = %i[id order_id type name probability impact measure].freeze

        class << self
          def call(api)
            register_clients(api)
            register_orders(api)
            register_uncertainties(api)
            register_children(api)
            order_routes(api)
          end

          def register_clients(api)
            # Replaces root.rb's read-only registration (and its response entity) with a writable one.
            api.crud Client,
                     read: %i[id crm_key allow_local sector_id e_bill_account_key work_item_id name shortname],
                     write: %i[crm_key allow_local sector_id e_bill_account_key],
                     nested: { work_item_attributes: %i[name shortname description] },
                     relationships: %i[sector contacts billing_addresses],
                     scope: ->(user) { user.management? || user.order_responsible? ? Client.all : Client.none }
          end

          def register_orders(api)
            api.crud Order,
                     read: ORDER_READ,
                     write: %i[crm_key kind_id responsible_id department_id status_id],
                     nested: { work_item_attributes: %i[name shortname description parent_id],
                               order_team_members_attributes: %i[employee_id comment],
                               order_contacts_attributes: %i[contact_id comment],
                               additional_crm_orders_attributes: %i[crm_key] },
                     relationships: %i[comments order_uncertainties order_risks order_chances],
                     scope: ->(_user) { Order.preload(:order_team_members, :order_contacts, :additional_crm_orders) },
                     prepare: ->(entry) { Orders.prepare_order(self, entry) }
          end

          def register_uncertainties(api)
            api.crud OrderUncertainty, read: UNCERTAINTY_READ
            [OrderRisk, OrderChance].each do |model|
              api.crud model,
                       read: UNCERTAINTY_READ,
                       write: %i[name probability impact measure],
                       create_only: %i[order_id],
                       prepare: ->(entry) { Orders.check_order_valid(self, entry) }
            end
          end

          def register_children(api)
            api.crud OrderComment,
                     read: %i[id order_id text creator_id updater_id created_at updated_at],
                     write: %i[text], create_only: %i[order_id],
                     except: %i[index destroy],
                     prepare: lambda { |entry|
                       error!({ error: 'Forbidden' }, 403) unless current_user.is_a?(Employee)
                       entry.updater = current_user
                       entry.creator ||= current_user
                     }
            # Read through /orders/:id/targets and /orders/:id/contract (authorized on the Order, like the HTML
            # controllers), so no generic routes.
            api.crud OrderTarget, read: %i[id order_id target_scope_id rating comment], except: %i[index show]
            api.crud Contract,
                     read: %i[id number start_date end_date payment_period reference sla notes],
                     except: %i[index show]
          end

          # HTML defaults (OrdersController#build_entry) and the client rule for the parent work item. Runs
          # before the generic authorization, so a responsible cannot hand the order to someone else.
          def prepare_order(endpoint, entry)
            if entry.new_record?
              if endpoint.current_user.is_a?(Employee)
                entry.department_id ||= endpoint.current_user.department_id
                entry.responsible_id ||= endpoint.current_user.id
              end
              check_parent(endpoint, entry.work_item) if entry.work_item&.parent_id
            elsif entry.work_item.parent_id_changed?
              parent_error(endpoint, 'kann nicht geändert werden')
            end
          end

          # Saving an uncertainty re-saves its order (major value). `save` swallows that RecordInvalid and would
          # answer 422 without any message, so surface the order's errors up front.
          def check_order_valid(endpoint, entry)
            order = entry.order
            return unless order && !order.valid?

            errors = order.errors.to_hash.transform_keys { |attr| "order.#{attr}" }
            endpoint.error!({ errors: }, 422)
          end

          def check_parent(endpoint, work_item)
            parent = WorkItem.find_by(id: work_item.parent_id)
            return if parent.present? && parent.with_ancestors.any?(&:client) &&
                      parent.order.blank? && parent.accounting_post.blank?

            parent_error(endpoint, 'muss ein Kunde oder eine Kategorie eines Kunden sein')
          end

          def parent_error(endpoint, message)
            endpoint.error!({ errors: { 'work_item.parent_id' => [message] } }, 422)
          end

          def order_routes(api)
            order_entity = Crud.resources.fetch(Order).entity
            target_entity = Crud.resources.fetch(OrderTarget).entity
            contract_entity = Crud.resources.fetch(Contract).entity

            api.resource 'orders' do
              route_param :id, type: Integer do
                { completed_at: :update_completed, committed_at: :update_committed }.each do |attr, action|
                  desc "Set #{attr} (end of an allowed month; null resets, management only)", success: order_entity
                  params { requires attr, type: Date, allow_blank: true }
                  patch attr.to_s.delete_suffix('_at') do
                    order = Order.find(params[:id])
                    authorize!(action, order)
                    date = params[attr]
                    error!({ errors: { attr => ['ist nicht erlaubt'] } }, 422) unless Completable.completion_dates(current_user).include?(date)
                    order[attr] = date
                    save!(order)
                    present order, with: order_entity
                  end
                end

                desc 'List targets of an order', success: target_entity, is_array: true
                get :targets do
                  order = Order.find(params[:id])
                  authorize!(:show_targets, order)
                  present order.targets.list.to_a, with: target_entity
                end

                desc 'Update targets of an order; all or nothing, errors keyed `targets.<id>.<attribute>`',
                     success: target_entity, is_array: true
                params do
                  requires :targets, type: Array do
                    requires :id, type: Integer
                    optional :rating, type: String
                    optional :comment, type: String
                  end
                end
                patch :targets do
                  order = Order.find(params[:id])
                  authorize!(:update_targets, order)
                  targets = order.targets.index_by(&:id)
                  changes = declared(params, include_missing: false)[:targets].map do |attrs|
                    [targets.fetch(attrs[:id]) { error!({ error: 'Not found' }, 404) },
                     attrs.to_h.symbolize_keys.slice(:rating, :comment)]
                  end
                  errors = {}
                  OrderTarget.transaction do
                    changes.each do |target, attrs|
                      next if target.update(attrs)

                      target.errors.each { |e| (errors["targets.#{target.id}.#{e.attribute}"] ||= []) << e.message }
                    end
                    raise ActiveRecord::Rollback if errors.any?
                  end
                  error!({ errors: }, 422) if errors.any?
                  present order.targets.list.reload.to_a, with: target_entity
                end

                desc 'Show the contract of an order', success: contract_entity
                get :contract do
                  order = Order.find(params[:id])
                  authorize!(:show_contract, order)
                  present order.contract || error!({ error: 'Not found' }, 404), with: contract_entity
                end

                desc 'Create or update the contract of an order', success: contract_entity
                params { Crud.declare(self, Contract, %i[number start_date end_date payment_period reference notes sla]) }
                put :contract do
                  order = Order.find(params[:id])
                  authorize!(:update_contract, order)
                  contract = order.contract || Contract.new(order:)
                  contract.assign_attributes(declared(params, include_missing: false).to_h)
                  save!(contract)
                  present contract, with: contract_entity
                end
              end
            end
          end
        end
      end
    end
  end
end
