# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ProjectController < ApplicationController

  
  # Checks if employee came from login or from direct url
  before_filter :authorize
  
  # Startpoint
  def index
    list
    render :action => 'list'
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
    @employee = Employee.find_all
  end
  
  # Creates new instance of project
  def newProject
    @project = Project.new
    @client = Client.find_all
  end
  
  # Create projectmembership
  def createProjectmembership
    @project = Project.find(params[:project_id])
    @employees = Employee.find(params[:employee_id])
    @employees.each do |e|
      Projectmembership.create(:project_id => @project.id,
                               :employee_id => e.id)
      end
    flash[:notice] = 'Projectmember was created.'
    redirect_to :action => 'showProject' , :id => @project
  end

  # Add projectmanagement
  def addProjectmanagement
    @project = Project.find(params[:project_id])
    @projectmembership = Projectmembership.find(params[:projectmembership_id])
    @projectmembership.update_attributes(:projectmanagement => true)
    flash[:notice] = "#{@projectmembership.employee.lastname} #{@projectmembership.employee.firstname} was added to projectmanager."
    redirect_to :action => 'showProject' , :id => @project
  end
  
  # Remove projectmanagement
  def removeProjectmanagement
    @project = Project.find(params[:project_id])
    @projectmembership = Projectmembership.find(params[:projectmembership_id])
    @projectmembership.update_attributes(:projectmanagement => false)
    flash[:notice] = "#{@projectmembership.employee.lastname} #{@projectmembership.employee.firstname} was removed from projectmanager."
    redirect_to :action => 'showProject' , :id => @project
  end
  
  # Destroy projectmembership
  def destroyProjectmembership
    @project = Project.find(params[:project_id])
    @projectmembership = Projectmembership.find(params[:projectmembership_id])
    Projectmembership.find(params[:projectmembership_id]).destroy
    flash[:notice] = "Projectmember #{@projectmembership.employee.lastname} was deleted."
    redirect_to :action => 'showProject' , :id => @project
  end
  
  # Saves new project on db
  def createProject
   @project = Project.new(params[:project])
    if @project.save
      flash[:notice] = 'Project was successfully created.'
      redirect_to :action => 'list'
    else
      flash[:notice] = 'Project was not created.'
      redirect_to :action => 'list'
    end
  end
  
  # Shows the editpage of project
  def editProject
    @project = Project.find(params[:id])
    @client = Client.find(:all)
  end
  
  # Stores the updated attributes of project
  def updateProject
    @project = Project.find(params[:id])
    if @project.update_attributes(params[:project])
      flash[:notice] = 'Project was successfully updated.'
      redirect_to :action => 'show', :id => @project
    else
      render :action => 'edit'
    end
  end
  
  # Stores the updated attributes of client
  def updateClient
    @client = Client.find(params[:id])
    if @client.update_attributes(params[:client])
      flash[:notice] = 'Client was successfully updated.'
      redirect_to :action => 'clientlist', :id => @client
    else
      render :action => 'editclient'
    end
  end
  
  # Deletes the chosen project
  def destroyProject
    Project.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
