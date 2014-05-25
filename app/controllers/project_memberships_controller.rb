# encoding: utf-8


class ProjectMembershipsController < MembershipsController

  include ProjectGroupable

  before_action :authorize

  helper_method :parent_path

  private

  def list
    subject
    @list = Employee.list
  end

  def activate_config(id)
    { project_id: project_id, employee_id: id }
  end

  def project_id
    params[:project_id]
  end

  def parent_path(options = {})
    polymorphic_path([main_group, group].compact.uniq, options)
  end

  def main_path
    "#{parent_path}/project_memberships"
  end

  def subject
    @subject ||= Project.find(project_id)
  end

  def authorized?
    super || managed_project?(subject)
  end

end