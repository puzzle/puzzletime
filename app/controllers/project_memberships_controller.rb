# encoding: utf-8


class ProjectMembershipsController < MembershipsController

  before_action :authorize

  private

  def list
    @subject = Project.find(project_id)
    @list = Employee.list
  end

  def activate_config(id)
    { project_id: project_id, employee_id: id }
  end

  def project_id
    params[:project_id]
  end

  def project_manager?
    @user.management? ||
      @user.managed_projects.collect { |p| p.id }.include?(project_id.to_i)
  end

  def authorize
    # TODO assert project_manager?
    super
  end

end