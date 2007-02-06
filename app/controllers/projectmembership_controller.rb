class ProjectmembershipController < ApplicationController
   
  before_filter :authenticate

  def list
    @project = Project.find(params[:group_id])
    @employees = Employee.list  
  end  
    
  def createManager
    setManager(true)
  end
  
  def removeManager
    setManager(false)
  end
  
  def createMembership
    if params.has_key?(:employee_id)
      params[:employee_id].each do |id|
        Projectmembership.create(:project_id => params[:group_id],
                                 :employee_id => id)
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
  
private

  def redirectToList
    redirect_to :action => 'list', 
                :page => params[:page], 
                :group_id => params[:group_id],
                :group_page => params[:group_page]
  end  

  def setManager(bool)
    projectmembership = Projectmembership.find(params[:id])
    projectmembership.update_attributes(:projectmanagement => bool)
    #reload list for user (old version is cached otherwise)
    @user.managed_projects(true) if projectmembership.employee == @user 
    flash[:notice] = "#{projectmembership.employee.label} wurde als Projektleiter " + (bool ? "erfasst" : "entfernt") 
    redirectToList
  end   
  
end