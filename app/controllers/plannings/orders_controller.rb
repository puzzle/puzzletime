module Plannings
  class OrdersController < BaseController

    def show
      @plannings = grouped_plannings
      @accounting_posts = load_accounting_posts
      @employees = load_employees
    end

    private

    def order
      @order ||= Order.find(params[:id])
    end

    def load_plannings
      super.joins(:work_item)
           .where('? = ANY (work_items.path_ids)', order.work_item_id)
    end

    def load_accounting_posts
      order.accounting_posts.where(closed: false).list.includes(:work_item)
    end

    def load_employees
      Employee.where(id: @plannings.values.map(&:keys).flatten.uniq).list
    end

    def grouped_plannings(plannings = load_plannings)
      grouped = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [] }}
      plannings.each do |planning|
        grouped[planning.work_item_id][planning.employee_id] << planning
      end
      grouped
    end

  end
end