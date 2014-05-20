# encoding: utf-8

class ProjectmembershipController < ApplicationController

  before_action :authenticate

  helper :manage
  helper_method :group
  hide_action :group

  def index
    list
  end

  def list
    employee? ? list_projects : list_employees
  end

  def list_projects
    id_group =  (! @user.management? || group_id.nil?) ? @user.id : group_id
    @subject = Employee.find(id_group)
    @list = Project.list.sort
    render action: 'list'
  end

  def list_employees
    return list_projects unless project_manager?
    @subject = Project.find(group_id)
    @list = Employee.list
    render action: 'list'
  end

  def create_manager
    set_manager(true)
  end

  def remove_manager
    set_manager(false)
  end

  def create_membership
    if params.key?(:ids)
      group_key = employee? ? :employee_id : :project_id
      entry = employee? ? :project_id : :employee_id
      id_group =  (employee? && ! @user.management?) ? @user.id : group_id
      params[:ids].each do |id|
        Projectmembership.activate(group_key => id_group, entry => id)
      end
      flash[:notice] = 'Der/Die Mitarbeiter wurden dem Projekt hinzugefügt'
    else
      flash[:notice] = 'Bitte wählen sie einen oder mehrere Mitarbeiter'
    end
    redirect_to_list
  end

  def remove_membership
    Projectmembership.deactivate(params[:id])
    flash[:notice] = 'Der Mitarbeiter wurde vom Projekt entfernt'
    redirect_to_list
  end

  def group
    @subject
  end

  private

  def employee?
    Project.name.downcase != params[:subject]
  end

  def project_manager?
    @user.management? ||
      @user.managed_projects.collect { |p| p.id }.include?(group_id.to_i)
  end

  def redirect_to_list
    redirect_to action: 'list',
                page: params[:page],
                subject: params[:subject],
                groups: params[:groups],
                group_ids: params[:group_ids],
                group_pages: params[:group_pages]
  end

  def set_manager(bool)
    projectmembership = Projectmembership.find(params[:id])
    projectmembership.update_attributes(projectmanagement: bool)
    # reload list for user (old version is cached otherwise)
    @user.managed_projects(true) if projectmembership.employee_id == @user.id
    flash[:notice] = "#{projectmembership.employee.label} wurde als Projektleiter " + (bool ? 'erfasst' : 'entfernt')
    redirect_to_list
  end

  def group_id
    last_param(:group_ids) || @user.id
  end

  def last_param(key)
    params[key].split('-').last if params[key]
  end
end
