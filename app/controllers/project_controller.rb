# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ProjectController < ApplicationController
  
  # Checks if employee came from login or from direct url.
  before_filter :authenticate
  before_filter :authorize, :only => [ :newProject, :createProject, 
                                       :deleteProject, :confirmDeleteProject ]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :createProject, :updateProject, :deleteProject ],
         :redirect_to => { :action => :listProject }

  def index
    redirect_to :action => 'listProject'
  end

  # Lists all projects.
  def listProject
    if @user.management then listAllProjects 
    else listManagedProjects   
    end
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
 
  # Saves new project on DB.
  def createProject   
   @project = Project.new(params[:project])
    if @project.save
      flash[:notice] = 'Project was successfully created'
      redirect_to :action => 'showProject', :id => @project
    else
      @clients = Client.list
      flash[:notice] = 'Project was not created'
      render :action => 'newProject'
    end
  end
  
  # Shows the editpage of project.
  def editProject
    @project = Project.find(params[:id])
    @clients = Client.list
  end
  
  # Stores the updated attributes of project.
  def updateProject
    @clients = Client.list
    @project = Project.find(params[:project_id])
    if @project.update_attributes(params[:project])
      flash[:notice] = 'Project was successfully updated'
      redirect_to :action => 'showProject', :id => @project
    else
      render :action => 'editProject'
    end
  end 
  
  def confirmDeleteProject
    @project = Project.find(params[:id])
  end
  
  # Deletes the chosen project.
  def deleteProject
    Project.destroy(params[:id])
    flash[:notice] = 'Project was successfully deleted'
    redirect_to :action => 'listProject'
  end
  
  def addProjectManagement
    setProjectManagement(true)
  end
  
  def removeProjectManagement
    setProjectManagement(false)
  end
  
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
    
  def removeProjectMembership
    Projectmembership.destroy(params[:projectmembership_id])
    flash[:notice] = "Projectmembership was deleted"
    redirect_to :action => 'showProject', :id => params[:project_id]
  end
  
private

  def setProjectManagement(bool)
    projectmembership = Projectmembership.find(params[:projectmembership_id])
    projectmembership.update_attributes(:projectmanagement => bool)
    if projectmembership.employee == @user 
      @user.managed_projects(true)  #reload list for user (old version is cached otherwise)
    end
    flash[:notice] = "#{projectmembership.employee.label} was " + (bool ? "set as" : "removed as") + " project manager"
    redirect_to :action => 'showProject' , :id => params[:project_id]
  end
  
  def listManagedProjects
    @project_pages = Paginator.new self, @user.managed_projects.count, NO_OF_OVERVIEW_ROWS, params[:page]
    @projects = @user.managed_projects.find(:all, 
                          :limit => @project_pages.items_per_page,
                          :offset => @project_pages.current.offset)   
  end
  
  def listAllProjects
    options = {:order => 'client_id, name', :per_page => NO_OF_OVERVIEW_ROWS}
    if params.has_key?(:client_id) 
      options[:conditions] = ['client_id = ?', params[:client_id]]
    end
    @project_pages, @projects = paginate :projects, options
  end
  
end
