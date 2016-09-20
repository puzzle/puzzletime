module Plannings
  class EmployeesController < BaseController

    def show
      @plannings = grouped_plannings
      @accounting_posts = load_accounting_posts
    end

    private

    def employee
      @employee ||= Employee.find(params[:id])
    end

    def grouped_plannings(plannings = load_plannings)
      plannings.group_by(&:work_item_id)
    end

    def load_plannings
      super.where(employee_id: employee.id)
    end

    def load_accounting_posts
      AccountingPost
        .where(work_item_id: @plannings.keys)
        .includes(:work_item)
        .list
    end

  end
end