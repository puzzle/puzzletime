# encoding: utf-8

module Plannings
  class EmployeesController < BaseController

    self.search_columns = [:firstname, :lastname, :shortname]

    before_render_show :load_accounting_posts

    private

    def employee
      @employee ||= Employee.find(params[:id])
    end

    def load_plannings
      super.where(employee_id: employee.id)
    end

    def load_accounting_posts
      @accounting_posts = AccountingPost
        .where(work_item_id: @plannings.map(&:work_item_id).uniq)
        .includes(:work_item)
        .list
    end

  end
end
