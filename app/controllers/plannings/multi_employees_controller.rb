#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Plannings
  class MultiEmployeesController < Plannings::EmployeesController
    skip_load_and_authorize_resource
    skip_before_action :authorize_subject_planning, only: :show

    def show
      authorize!(:read, Planning)
      @boards = employees.collect { |e| Plannings::EmployeeBoard.new(e, @period) }
    end

    private

    def employees
      @employees ||= begin
        if params[:department_id]
          d = Department.find(params[:department_id])
          @title = "Planung der Members von #{d}"
          d.employees.employed_ones(@period).list
        elsif params[:custom_list_id]
          CustomList.where(item_type: Employee.sti_name).find(params[:custom_list_id]).items.list
        else
          raise ActiveRecord::RecordNotFound
        end
      end
    end

    def employee
      @employee ||= Employee.find(relevant_employee_id)
    end
    alias subject employee

    def relevant_employee_id
      if params[:employee_id] # new
        params[:employee_id]
      elsif params[:items].present? # update
        Array(params[:items].to_unsafe_h.first).last[:employee_id]
      elsif params[:planning_ids].present? # destroy
        Planning.find(params[:planning_ids].first).employee_id
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
