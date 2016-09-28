# encoding: utf-8

module Plannings
  class EmployeesController < BaseController

    self.search_columns = [:firstname, :lastname, :shortname]

    skip_authorize_resource

    private

    def list_entries
      super.employed_ones(Period.current_year)
    end

    def employee
      @employee ||= Employee.find(params[:id])
    end
    alias_method :subject, :employee

    def build_board
      Plannings::EmployeeBoard.new(employee, @period)
    end

    def params_with_restricted_items
      super.tap do |p|
        p[:items].select! do |hash|
          hash[:employee_id].to_i == employee.id
        end
      end
    end

    def plannings_to_destroy
      super.where(employee_id: employee.id)
    end

  end
end
