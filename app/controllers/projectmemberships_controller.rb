# encoding: utf-8

class ProjectmembershipsController < ApplicationController

  # TODO move to application controller
  before_action :authenticate

  def show
    employee? ? list_projects : list_employees
    @projects = @subject.projectmemberships.where(active: true).
                                            sort_by { |m| m.project }
  end

  def create_manager
    set_manager(true)
  end

  def destroy_manager
    set_manager(false)
  end

  def create_membership
    if params.key?(:ids)
      params[:ids].each do |id|
        config = employee? ? employee_config(id) : project_config(id)
        Projectmembership.activate(config)
      end
      flash[:notice] = 'Der/Die Mitarbeiter wurden dem Projekt hinzugefügt'
    else
      flash[:notice] = 'Bitte wählen sie einen oder mehrere Mitarbeiter'
    end
    redirect_to_list
  end

  def destroy_membership
    Projectmembership.deactivate(params[:id])
    flash[:notice] = 'Der Mitarbeiter wurde vom Projekt entfernt'
    redirect_to_list
  end

  private

  def list_projects
    @subject = Employee.find(employee_id)
    @list = Project.list.sort
  end

  def list_employees
    return list_projects unless project_manager?
    @subject = Project.find(project_id)
    @list = Employee.list
  end

  def employee_config(id)
    { employee_id: employee_id, project_id: id }
  end

  def project_config(id)
    { project_id: project_id, employee_id: id }
  end

  def project_manager?
    @user.management? ||
      @user.managed_projects.collect { |p| p.id }.include?(project_id.to_i)
  end

  def redirect_to_list
    redirect_to action: 'index'
  end

  def set_manager(bool)
    projectmembership = Projectmembership.find(params[:id])
    projectmembership.update_attributes!(projectmanagement: bool)
    # reload list for user (old version is cached otherwise)
    @user.managed_projects(true) if projectmembership.employee_id == @user.id
    flash[:notice] = "#{projectmembership.employee} wurde als Projektleiter #{bool ? 'erfasst' : 'entfernt'}"
    redirect_to_list
  end

  def employee?
    project_id.nil?
  end

  def employee_id
    (@user.management && params[:employee_id]) || @user.id
  end

  def project_id
    params[:project_id]
  end

end
