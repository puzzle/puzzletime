# encoding: utf-8

module Plannings
  class EmployeesController < BaseController

    self.search_columns = [:firstname, :lastname, :shortname]

    private

    def list_entries
      super.employed_ones(Period.current_year)
    end

    def employee
      @employee ||= Employee.find(params[:id])
    end
    alias_method :entry, :employee

    def load_plannings
      super.where(employee_id: employee.id)
    end

    def load_accounting_posts
      AccountingPost
        .where(work_item_id: @plannings.map(&:work_item_id).uniq)
        .includes(:work_item)
        .list
    end

    def load_employees
      employee
    end

  end
end
