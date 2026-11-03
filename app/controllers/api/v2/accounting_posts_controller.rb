# frozen_string_literal: true

module Api
  module V2
    # Serves AccountingPostResource; `by_order` is `GET /orders/:id/accounting_posts`.
    class AccountingPostsController < ResourceController
      def by_order
        order = Order.find(params[:id])
        authorize!(:accounting_posts, order)
        params[:filter] = (params[:filter]&.to_unsafe_h || {}).merge(order_id: order.id)
        render jsonapi: AccountingPostResource.all(params)
      end
    end
  end
end
