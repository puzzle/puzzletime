# encoding: utf-8

module Plannings
  class OrdersController < BaseController

    self.search_columns = %w(work_items.name work_items.shortname
                             work_items.path_names work_items.path_shortnames)

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

    def build_board
      Plannings::OrderBoard.new(order, @period)
    end

  end
end
