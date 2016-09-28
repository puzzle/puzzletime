# encoding: utf-8

module Plannings
  class MultiOrdersController < OrdersController

    skip_load_and_authorize_resource
    skip_before_action :authorize_subject_planning, only: :show

    def show
      authorize!(:read, Planning)
      @boards = orders.collect { |o| Plannings::OrderBoard.new(o, @period) }
    end

    private

    def orders
      @orders ||= begin
        if params[:department_id]
          d = Department.find(params[:department_id])
          @title = "Planung der Aufträge von #{d}"
          d.orders.where('work_items.closed = ?', false).list
        else
          raise ActiveRecord::RecordNotFound
        end
      end
    end

    def order
      @order ||= order_for_work_item_id(relevant_work_item_id)
    end
    alias subject order

    def relevant_work_item_id
      if params[:work_item_id] # new
        params[:work_item_id]
      elsif params[:items].present? # update
        Array(params[:items].first).last[:work_item_id]
      elsif params[:planning_ids].present? # destroy
        Planning.find(params[:planning_ids].first).work_item_id
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    def order_for_work_item_id(work_item_id)
      Order.joins('LEFT JOIN work_items ON ' \
                  'orders.work_item_id = ANY (work_items.path_ids)').
        find_by('work_items.id = ?', work_item_id)
    end

  end
end
