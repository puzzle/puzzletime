class ProjectmembershipController < ApplicationController

  before_action :authenticate

  helper :manage
  helper_method :group
  hide_action :group

  def index
    list
  end

  def list
    employee? ? listProjects : listEmployees
  end

  def listProjects
    id_group =  (! @user.management? || group_id.nil?) ? @user.id : group_id
    @subject = Employee.find(id_group)
    @list = Project.list.sort
    render action: 'list'
  end

  def listEmployees
    return listProjects unless projectManager?
    @subject = Project.find(group_id)
    @list = Employee.list
    render action: 'list'
  end

  def createManager
    setManager(true)
  end

  def removeManager
    setManager(false)
  end

  def createMembership
    if params.key?(:ids)
      group_key = employee? ? :employee_id : :project_id
      entry = employee? ? :project_id : :employee_id
      id_group =  (employee? && ! @user.management?) ? @user.id : group_id
      params[:ids].each do |id|
        Projectmembership.activate(group_key => id_group, entry => id)
      end
      flash[:notice] = 'Der/Die Mitarbeiter wurden dem Projekt hinzugef&uuml;gt'
    else
      flash[:notice] = 'Bitte w&auml;hlen sie einen oder mehrere Mitarbeiter'
    end
    redirectToList
  end

  def removeMembership
    Projectmembership.deactivate(params[:id])
    flash[:notice] = 'Der Mitarbeiter wurde vom Projekt entfernt'
    redirectToList
  end

  def group
    @subject
  end

  private

  def employee?
    Project.name.downcase != params[:subject]
  end

  def projectManager?
    @user.management? ||
      @user.managed_projects.collect { |p| p.id }.include?(group_id.to_i)
  end

  def redirectToList
    redirect_to action: 'list',
                page: params[:page],
                subject: params[:subject],
                groups: params[:groups],
                group_ids: params[:group_ids],
                group_pages: params[:group_pages]
  end

  def setManager(bool)
    projectmembership = Projectmembership.find(params[:id])
    projectmembership.update_attributes(projectmanagement: bool)
    # reload list for user (old version is cached otherwise)
    @user.managed_projects(true) if projectmembership.employee_id == @user.id
    flash[:notice] = "#{projectmembership.employee.label} wurde als Projektleiter " + (bool ? 'erfasst' : 'entfernt')
    redirectToList
  end

  def group_id
    last_param(:group_ids) || @user.id
  end

  def last_param(key)
    params[key].split('-').last if params[key]
  end
end
