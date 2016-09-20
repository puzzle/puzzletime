module Plannings
  class OrdersController < BaseController

    before_render_show :load_accounting_posts
    before_render_show :load_employees

    private

    def order
      @order ||= Order.find(params[:id])
    end

    def load_plannings
      super.joins(:work_item)
           .where('? = ANY (work_items.path_ids)', order.work_item_id)
    end

    def load_accounting_posts
      @accounting_posts = order.accounting_posts.where(closed: false).list.includes(:work_item)
    end

    def load_employees
      @employees = Employee.where(id: @plannings.map(&:employee_id).uniq).list
    end

  end
end