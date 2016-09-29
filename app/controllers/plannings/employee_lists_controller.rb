# encoding: utf-8

module Plannings
  class EmployeeListsController < CrudController

    self.nesting = [:plannings]
    self.permitted_attrs = [:title, employee_ids: []]

    before_render_show :set_employees
    before_render_form :set_current_employees

    private

    def set_employees
      @employees = @employee_list.employees.list
    end

    def set_current_employees
      @curr_employees = Employee.employed_ones(Period.current_year)
    end

    def model_scope
      @user.employee_lists
    end

  end
end
