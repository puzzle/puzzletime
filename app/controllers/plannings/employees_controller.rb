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

    def build_board
      Plannings::EmployeeBoard.new(employee, @period)
    end

  end
end
