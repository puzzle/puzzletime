# encoding: utf-8

class OvertimeVacationsController < ManageController
  self.nesting = Employee

  self.permitted_attrs = [:hours, :transfer_date]

  def show
    redirect_to employee_overtime_vacations_path(entry.employee)
  end
end
