# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # What does not fit the five Graphiti actions on an order: the completed/committed month (their own rules,
    # OrdersController does them through Orders::{Completed,Committed}Controller), all targets at once
    # (OrderTargetsController) and the contract (ContractsController).
    #
    # Bodies are JSON:API documents; the order is only ever authorized as a whole (`update_completed`, ...).
    class OrderOperationsController < BaseController
      TARGET_ATTRIBUTES = %i[rating comment].freeze

      # The order a contract is written to (read by ContractResource).
      attr_reader :order

      def completed
        update_month(:completed_at, :update_completed)
      end

      def committed
        update_month(:committed_at, :update_committed)
      end

      # All or nothing: errors of any target roll all of them back and are listed per target.
      def update_targets
        @order = Order.find(params[:id])
        authorize!(:update_targets, order)
        changes = target_changes
        errors = {}
        Order.transaction do
          errors = save_targets(changes)
          raise ActiveRecord::Rollback if errors.any?
        end
        return render_errors(errors) if errors.any?

        render jsonapi: OrderTargetResource.all(filter: { order_id: order.id })
      end

      def contract
        @order = Order.find(params[:id])
        authorize!(:show_contract, order)
        raise ActiveRecord::RecordNotFound, 'order has no contract' unless order.contract_id

        render jsonapi: ContractResource.find(params.merge(id: order.contract_id))
      end

      # Creates the contract of the order, or updates the existing one.
      def update_contract
        @order = Order.find(params[:id])
        authorize!(:update_contract, order)
        proxy = order.contract ? contract_update_proxy : ContractResource.build(params)
        if order.contract ? proxy.update : proxy.save
          render jsonapi: proxy
        else
          render jsonapi_errors: proxy
        end
      end

      private

      def update_month(attribute, action)
        order = Order.find(params[:id])
        authorize!(action, order)
        date = requested_date(attribute)
        return render_errors({ "attributes/#{attribute}" => 'ist nicht erlaubt' }) unless allowed?(date)

        order[attribute] = date
        return render_errors(error_messages(order, 'attributes/')) unless order.save

        render jsonapi: OrderResource.find(params.slice(:id, :include, :fields))
      end

      def allowed?(date)
        Completable.completion_dates(current_user).include?(date)
      end

      def requested_date(attribute)
        value = params.dig(:data, :attributes, attribute)
        value && Date.iso8601(value.to_s)
      rescue Date::Error
        value
      end

      def contract_update_proxy
        ContractResource.find(params.deep_merge(id: order.contract_id, data: { id: order.contract_id.to_s }))
      end

      # [[target, attributes], ...]
      def target_changes
        targets = order.targets.index_by(&:id)
        Array(params[:data]).map do |item|
          [targets.fetch(item[:id].to_i) { raise ActiveRecord::RecordNotFound, "target #{item[:id]}" },
           item.fetch(:attributes, {}).permit(*TARGET_ATTRIBUTES)]
        end
      end

      # Errors of all targets, keyed by the pointer into the request's `data`.
      def save_targets(changes)
        changes.each_with_index.reduce({}) do |errors, ((target, attributes), index)|
          target.update(attributes) ? errors : errors.merge(error_messages(target, "#{index}/attributes/"))
        end
      end

      def error_messages(model, prefix)
        model.errors.to_hash.transform_keys { |attribute| "#{prefix}#{attribute}" }
      end

      # `errors`: pointer below /data => message(s).
      def render_errors(errors)
        documents = errors.flat_map do |pointer, messages|
          Array(messages).map do |message|
            { status: '422', title: 'Validation Error', detail: message, source: { pointer: "/data/#{pointer}" } }
          end
        end
        render json: { errors: documents }, status: :unprocessable_content, content_type: Mime[:jsonapi]
      end
    end
  end
end
