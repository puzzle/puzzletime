# encoding: utf-8

module Plannings
  class MultiEmployeesController < EmployeesController

    skip_load_and_authorize_resource

    def show
      @boards = employees.collect { |e| Plannings::EmployeeBoard.new(e, @period) }
    end

    private

    def employees
      @employees ||= begin
        if params[:department_id]
          d = Department.find(params[:department_id])
          @title = "Planung der Mitarbeiter von #{d}"
          d.employees.employed_ones(@period).list
        else
          raise ActiveRecord::RecordNotFound
        end
      end
    end

    def employee
      @employee ||= Employee.find(relevant_employee_id)
    end

    def relevant_employee_id
      if params[:employee_id] # new
        params[:employee_id]
      elsif params[:items].present? # update
        Array(params[:items].first).last[:employee_id]
      elsif @plannings.present? # destroy
        @plannings.first.employee_id
      else
        raise ActiveRecord::RecordNotFound
      end
    end

  end
end
