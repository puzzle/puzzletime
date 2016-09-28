# encoding: utf-8

module Plannings
  class OrdersController < BaseController

    self.search_columns = %w(work_items.name work_items.shortname
                             work_items.path_names work_items.path_shortnames)

    skip_authorize_resource

    private

    def list_entries
      if params[:mine]
        super.where(responsible_id: current_user.id)
      else
        super
      end
    end

    def order
      @order ||= Order.find(params[:id])
    end
    alias subject order

    def build_board
      Plannings::OrderBoard.new(order, @period)
    end

    def params_with_restricted_items
      allowed_ids = order.work_item.self_and_descendants.leaves.pluck(:id)
      super.tap do |p|
        p[:items].select! do |hash|
          allowed_ids.include?(hash[:work_item_id].to_i)
        end
      end
    end

    def plannings_to_destroy
      super.joins(:work_item).
        where('? = ANY (work_items.path_ids)', order.work_item_id)
    end

  end
end
