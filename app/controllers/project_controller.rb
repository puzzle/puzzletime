# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ProjectController < ApplicationController

  
  # Checks if employee came from login or from direct url
  before_filter :authorize
  
  # Startpoint
  def index
    list
    render :action => 'listProject'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  # Lists all projects
  def listProject
    @project_pages, @projects = paginate :projects, :per_page => 10
  end
  
  # Shows detail of chosen project
  def showProject
    @project = Project.find(params[:id])
    @employee = Employee.find(:all, :order => 'lastname')
  end
  
  # Creates new instance of project
  def newProject
    @clients = Client.find(:all)
  end
  
  # Create project membership
  def createProjectMembership
    @project = Project.find(params[:project_id])
    if params.has_key?(:employee_id)
      @employees = Employee.find(params[:employee_id])
      @employees.each do |e|
        Projectmembership.create(:project_id => @project.id,
                               :employee_id => e.id)
      end      
      flash[:notice] = 'Projectmember was created'
      redirect_to :action => 'showProject' , :id => @project
    else
      flash[:notice] = 'Please select one or more employees'
      redirect_to :action => 'showProject' , :id => @project
    end
  end

  # Add project management
  def addProjectManagement
    @project = Project.find(params[:project_id])
    @projectmembership = Projectmembership.find(params[:projectmembership_id])
    @projectmembership.update_attributes(:projectmanagement => true)
    flash[:notice] = "#{@projectmembership.employee.lastname} #{@projectmembership.employee.firstname} was added to projectmanager"
    redirect_to :action => 'showProject' , :id => @project
  end
  
  # Remove project management
  def removeProjectManagement
    @project = Project.find(params[:project_id])
    @projectmembership = Projectmembership.find(params[:projectmembership_id])
    @projectmembership.update_attributes(:projectmanagement => false)
    flash[:notice] = "#{@projectmembership.employee.lastname} #{@projectmembership.employee.firstname} was removed from projectmanager"
    redirect_to :action => 'showProject' , :id => @project
  end
  
  # Destroy project membership
  def destroyProjectMembership
    @project = Project.find(params[:project_id])
    @projectmembership = Projectmembership.find(params[:projectmembership_id])
    Projectmembership.find(params[:projectmembership_id]).destroy
    flash[:notice] = "Projectmember #{@projectmembership.employee.lastname} #{@projectmembership.employee.firstname} was deleted"
    redirect_to :action => 'showProject' , :id => @project
  end
  
  # Saves new project on db
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
  
  # Shows the editpage of project
  def editProject
    @project = Project.find(params[:id])
    @clients = Client.find(:all)
  end
  
  # Stores the updated attributes of project
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
  
  def changeProject
    if @user.management == true
      @projects = Project.find(:all, :order => "name")
    else
      @projectmemberships = Projectmembership.find(:all, :conditions =>["employee_id = ? and projectmanagement IS TRUE", @user.id])
    end
    @old_project = Worktime.find(params[:worktime_id])
  end
  
  def updateEmployeeChangedProject
    @worktime = Worktime.find(params[:worktime_id])
    if @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Project was successfully changed'
      redirect_to :controller => 'evaluator', :action => 'showProjects'
    else
      render :action => 'changeProject'
    end
  end
  
  # Deletes the chosen project
  def destroyProject
    Project.find(params[:id]).destroy
    flash[:notice] = 'Project was successfully deleted'
    redirect_to :action => 'listProject'
  end
end
