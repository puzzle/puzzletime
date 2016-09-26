# encoding: utf-8

module Plannings
  class OrdersController < BaseController

    self.search_columns = %w(work_items.name work_items.shortname
                             work_items.path_names work_items.path_shortnames)

    private

    def order
      @order ||= Order.find(params[:id])
    end
    alias_method :entry, :order

    def build_board
      Plannings::OrderBoard.new(order, @period)
    end

  end
end
