# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    module Resources
      # AccountingPost (read + writes through AccountingPost#attach_work_item), Invoice and Planning (read-only).
      #
      # Invoice writes are intentionally not exposed: they sync with the remote Invoicing system, destroying
      # soft-cancels sent invoices and the status/defaults workflow lives in InvoicesController.
      # Planning writes are not exposed: the model lacks validations the HTML Plannings::Creator relies on.
      module Accounting
        POST_ATTRS = %i[closed offered_hours offered_rate offered_total remaining_hours portfolio_item_id service_id
                        billable description_required ticket_required from_to_times_required meal_compensation
                        billing_reminder_active].freeze

        class << self
          # Employees may read posts of every order they can see (Ability `can :read, AccountingPost`,
          # Order#accounting_posts for everyone); writes stay per instance in Ability.
          def posts_scope(user)
            user.is_a?(Employee) ? AccountingPost.all : AccountingPost.none
          end

          # Invoices carry amounts: management sees all, order responsibles those of their orders.
          def invoices_scope(user)
            return Invoice.all if user.management?
            return Invoice.none unless user.is_a?(Employee)

            Invoice.where(order_id: Order.where(responsible_id: user.id).select(:id))
          end

          # Management sees all, others their own rows plus rows below orders they are responsible for.
          def plannings_scope(user)
            return Planning.all if user.management?
            return Planning.none unless user.is_a?(Employee)

            Planning.where(employee_id: user.id).or(Planning.where(<<~SQL.squish, user.id))
              EXISTS (SELECT 1 FROM work_items wi JOIN orders o ON o.work_item_id = ANY (wi.path_ids)
                      WHERE wi.id = plannings.work_item_id AND o.responsible_id = ?)
            SQL
          end

          # Mirrors AccountingPostsController#assign_attributes. Callers authorize first; the order of a
          # post cannot change, so nothing is persisted for a forbidden request.
          def save_post?(entry, order, attrs, book_on_order:)
            original_id = entry.work_item_id
            entry.attach_work_item(order, attrs, book_on_order)
            return true if entry.save

            discard_work_item(entry, order, original_id)
            false
          end

          # attach_work_item persists a work item before the post is validated (as in the HTML controller);
          # remove it again when the post is rejected so no orphan stays behind.
          def discard_work_item(entry, order, original_id)
            item = entry.work_item
            return unless item&.persisted? && [original_id, order.work_item_id].exclude?(item.id)

            item.destroy
          end
        end

        def self.call(api)
          accounting_posts(api)
          invoices(api)
          plannings(api)
        end

        def self.accounting_posts(api)
          api.crud AccountingPost,
                   read: [:id, *POST_ATTRS, :work_item_id],
                   scope: ->(user) { Accounting.posts_scope(user) }
          entity = Crud.resources.fetch(AccountingPost).entity

          api.resource('accounting_posts') do
            desc 'Create an accounting post below an order', success: entity
            params do
              requires :order_id, type: Integer
              Crud.declare(self, AccountingPost, POST_ATTRS)
              optional :book_on_order, type: Grape::API::Boolean, desc: 'Book directly on the order'
              optional :work_item_attributes, type: Hash do
                optional :name, type: String
                optional :shortname, type: String
                optional :description, type: String
              end
            end
            post do
              order = Crud.base(Order, current_user).find(params[:order_id])
              attrs = declared(params, include_missing: false).to_h.symbolize_keys
              entry = AccountingPost.new(attrs.slice(*POST_ATTRS))
              entry.build_work_item(parent_id: order.work_item_id)
              authorize!(:create, entry)
              Accounting.save_post?(entry, order, attrs[:work_item_attributes],
                                    book_on_order: attrs[:book_on_order] == true) ||
                error!({ errors: entry.errors.to_hash }, 422)
              present entry, with: entity
            end

            route_param :id, type: Integer do
              desc 'Update an accounting post', success: entity
              params do
                Crud.declare(self, AccountingPost, POST_ATTRS)
                optional :book_on_order, type: Grape::API::Boolean, desc: 'Book directly on the order'
                optional :work_item_attributes, type: Hash do
                  optional :name, type: String
                  optional :shortname, type: String
                  optional :description, type: String
                end
              end
              patch do
                entry = Crud.base(AccountingPost, current_user).find(params[:id])
                authorize!(:update, entry)
                attrs = declared(params, include_missing: false).to_h.symbolize_keys
                entry.assign_attributes(attrs.slice(*POST_ATTRS))
                Accounting.save_post?(entry, entry.order, attrs[:work_item_attributes],
                                      book_on_order: attrs[:book_on_order] == true) ||
                  error!({ errors: entry.errors.to_hash }, 422)
                present entry, with: entity
              end

              desc 'Delete an accounting post (not possible while it has worktimes)'
              delete do
                entry = Crud.base(AccountingPost, current_user).find(params[:id])
                authorize!(:destroy, entry)
                error!({ errors: entry.errors.to_hash }, 422) unless entry.destroy
                status 204
                body false
              end
            end
          end

          api.resource('orders') do
            route_param :id, type: Integer do
              desc 'List accounting posts of an order', success: entity, is_array: true
              params { use :pagination }
              get 'accounting_posts' do
                order = Crud.base(Order, current_user).find(params[:id])
                authorize!(:accounting_posts, order)
                posts = Crud.base(AccountingPost, current_user).merge(order.accounting_posts)
                present paginate(posts.list), with: entity
              end
            end
          end
        end

        def self.invoices(api)
          api.crud Invoice,
                   read: %i[id order_id billing_address_id billing_date due_date period_from period_to status grouping
                            reference total_amount total_hours],
                   scope: ->(user) { Accounting.invoices_scope(user) }
          Crud.relate(Order, :invoices)
        end

        def self.plannings(api)
          api.crud Planning,
                   read: %i[id employee_id work_item_id date percent definitive],
                   scope: ->(user) { Accounting.plannings_scope(user) }
        end
      end
    end
  end
end
