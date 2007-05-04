class ProjectmembershipController < ApplicationController
   
  before_filter :authenticate
  
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
    params[:group_id] = @user.id if ! @user.management? || params[:group_id].nil?
    @subject = Employee.find(params[:group_id])
    @list = Project.list
    render :action => 'list'
  end
  
  def listEmployees 
    return listProjects if ! projectManager?   
    @subject = Project.find(params[:group_id])
    @list = Employee.list  
    render :action => 'list'
  end 

  def createManager    
    setManager(true)
  end
  
  def removeManager
    setManager(false)
  end
  
  def createMembership
    if params.has_key?(:ids)
      group = employee? ? :employee_id : :project_id 
      entry = employee? ? :project_id : :employee_id 
      params[:group_id] = @user.id if employee? && ! @user.management?       
      params[:ids].each do |id|        
        Projectmembership.create(group => params[:group_id],
                                   entry => id)                          
        @user.projects(true) if (employee? && @user.id == params[:group_id]) || @user.id == id                         
      end      
      flash[:notice] = 'Der/Die Mitarbeiter wurden dem Projekt hinzugef&uuml;gt'
    else
      flash[:notice] = 'Bitte w&auml;hlen sie einen oder mehrere Mitarbeiter'
    end
    redirectToList
  end  
    
  def removeMembership
    Projectmembership.destroy(params[:id])
    flash[:notice] = "Der Mitarbeiter wurde vom Projekt entfernt"
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
      @user.managed_projects.collect{|p| p.id}.include?(params[:group_id].to_i)
  end

  def redirectToList
    redirect_to :action => 'list', 
                :page => params[:page], 
                :group_id => params[:group_id],
                :group_page => params[:group_page],
                :subject => params[:subject]
  end       

  def setManager(bool)
    projectmembership = Projectmembership.find(params[:id])
    projectmembership.update_attributes(:projectmanagement => bool)
    #reload list for user (old version is cached otherwise)
    @user.managed_projects(true) if projectmembership.employee_id == @user.id 
    flash[:notice] = "#{projectmembership.employee.label} wurde als Projektleiter " + (bool ? "erfasst" : "entfernt") 
    redirectToList
  end   
  
end