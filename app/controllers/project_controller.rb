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
    @clients = Client.list
  end
 
  # Saves new project on DB.
  def createProject   
   @project = Project.new(params[:project])
    if @project.save
      flash[:notice] = 'Das Projekt wurde erfasst'
      redirect_to :action => 'showProject', :id => @project
    else
      @clients = Client.list
      flash[:notice] = 'Das Projekt konnte nicht erfasst werden'
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
      flash[:notice] = 'Das Projekt wurde aktualisiert'
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
    begin
      Project.destroy(params[:id])
      flash[:notice] = 'Das Projekt wurde entfernt'
    rescue Exception => err
      flash[:notice] = err.message
    end      
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
      flash[:notice] = 'Der Mitarbeiter wurde dem Projekt hinzugef&uuml;gt'
      redirect_to :action => 'showProject' , :id => params[:project_id]
    else
      flash[:notice] = 'Bitte w&auml;hlen sie einen oder mehrere Mitarbeiter'
      redirect_to :action => 'showProject' , :id => params[:project_id]
    end
  end  
    
  def removeProjectMembership
    Projectmembership.destroy(params[:projectmembership_id])
    flash[:notice] = "Der Mitarbeiter wurde vom Projekt entfernt"
    redirect_to :action => 'showProject', :id => params[:project_id]
  end
  
private  

  def setProjectManagement(bool)
    projectmembership = Projectmembership.find(params[:projectmembership_id])
    projectmembership.update_attributes(:projectmanagement => bool)
    if projectmembership.employee == @user 
      @user.managed_projects(true)  #reload list for user (old version is cached otherwise)
    end
    flash[:notice] = "#{projectmembership.employee.label} wurde als Projektleiter " + (bool ? "erfasst" : "entfernt") 
    redirect_to :action => 'showProject', :id => params[:project_id]
  end
  
  def listManagedProjects
    @project_pages = Paginator.new self, @user.managed_projects.count, NO_OF_OVERVIEW_ROWS, params[:page]
    @projects = @user.managed_projects.find(:all, 
                          :limit => @project_pages.items_per_page,
                          :offset => @project_pages.current.offset)   
  end
  
  def listAllProjects
    @project_pages = Paginator.new self, Project.count, NO_OF_OVERVIEW_ROWS, params[:page]
   
    options = {:limit => @project_pages.items_per_page,
               :offset => @project_pages.current.offset}
    if params.has_key?(:client_id) 
      options[:conditions] = ['client_id = ?', params[:client_id]]
    end
    @projects = Project.list(options)
  end
  
end
