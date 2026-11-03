# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # `GET /orders/:id/<children>`: the rows of a related resource that belong to one order (the same as
    # `GET /<children>?filter[order_id]=:id`, for the ones without an index of their own).
    #
    # Authorization like the HTML controllers: showing the order, plus the order's ability for the child (or the
    # child model's, where Ability has no per-order rule). Which rows are visible is up to the child resource.
    class OrderChildrenController < BaseController
      CHILDREN = {
        'comments' => [OrderCommentResource, :show_comments],
        'order_uncertainties' => [OrderUncertaintyResource, :show_uncertainties],
        'order_risks' => [OrderRiskResource, :show_uncertainties],
        'order_chances' => [OrderChanceResource, :show_uncertainties],
        'targets' => [OrderTargetResource, :show_targets],
        'invoices' => [InvoiceResource, nil],
        'accounting_posts' => [AccountingPostResource, nil]
      }.freeze

      def index
        resource, action = CHILDREN.fetch(params[:children])
        order = Order.find(params[:id])
        authorize!(:show, order)
        action ? authorize!(action, order) : authorize!(:index, resource.model)
        # `all` would refuse the path (the resource's own endpoint is /<children>); `_all` is what it calls after that check.
        render jsonapi: resource._all(params.except(:id, :children).merge(filter: order_filter(order)), {}, nil)
      end

      private

      # The request's own filters, narrowed to the order.
      def order_filter(order)
        filter = params[:filter]
        (filter.is_a?(ActionController::Parameters) ? filter : ActionController::Parameters.new).merge(order_id: order.id)
      end
    end
  end
end
