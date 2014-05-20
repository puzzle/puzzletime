# encoding: utf-8

class EmployeeMembershipsController < MembershipsController

  private


  def list
    @subject = Employee.find(employee_id)
    @list = Project.list.sort
  end

  def activate_config(id)
    { employee_id: employee_id, project_id: id }
  end

  def employee_id
    (@user.management && params[:employee_id]) || @user.id
  end

end