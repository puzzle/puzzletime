# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ProjectController < ApplicationController

  
  # Checks if employee came from login or from direct url.
  before_filter :authorize

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  # Lists all projects.
  def listProject
    @project_pages, @projects = paginate :projects, :order => 'client_id, name', :per_page => 10
  end
  
  # Shows detail of chosen project.
  def showProject
    @project = Project.find(params[:id])
    @employees = Employee.list
  end
  
  # Creates new instance of project.
  def newProject
    @clients = Client.find(:all)
  end
  
  # Create project membership.
  def createProjectMembership
    if params.has_key?(:employee_id)
      @employees = Employee.find(params[:employee_id])
      @employees.each do |e|
        Projectmembership.create(:project_id => params[:project_id],
                                 :employee_id => e.id)
      end      
      flash[:notice] = 'Projectmember was created'
      redirect_to :action => 'showProject' , :id => params[:project_id]
    else
      flash[:notice] = 'Please select one or more employees'
      redirect_to :action => 'showProject' , :id => params[:project_id]
    end
  end

  # Add project management.
  def addProjectManagement
    setProjectManagement(true)
  end
  
  # Remove project management.
  def removeProjectManagement
    setProjectManagement(false)
  end
  
  # Destroy project membership.
  def destroyProjectMembership
    Projectmembership.destroy(params[:projectmembership_id])
    flash[:notice] = "Projectmembership was deleted"
    redirect_to :action => 'showProject', :id => params[:project_id]
  end
  
  # Saves new project on DB.
  def createProject
   @clients = Client.find(:all)
   @project = Project.new(params[:project])
    if @project.save
      flash[:notice] = 'Project was successfully created'
      redirect_to :action => 'listProject'
    else
      flash[:notice] = 'Project was not created'
      render :action => 'newProject'
    end
  end
  
  # Shows the editpage of project.
  def editProject
    @project = Project.find(params[:id])
    @clients = Client.find(:all)
  end
  
  # Stores the updated attributes of project.
  def updateProject
    @clients = Client.find(:all)
    @project = Project.find(params[:project_id])
    if @project.update_attributes(params[:project])
      flash[:notice] = 'Project was successfully updated'
      redirect_to :action => 'showProject', :id => @project
    else
      render :action => 'editProject'
    end
  end
 
  
  # Deletes the chosen project.
  def destroyProject
    Project.destroy(params[:id])
    flash[:notice] = 'Project was successfully deleted'
    redirect_to :action => 'listProject'
  end
  
private

  def setProjectManagement(bool)
    projectmembership = Projectmembership.find(params[:projectmembership_id])
    projectmembership.update_attributes(:projectmanagement => bool)
    flash[:notice] = "#{projectmembership.employee.label} was " + (bool ? "set as" : "removed as") + " project manager"
    redirect_to :action => 'showProject' , :id => params[:project_id]
  end
  
end
