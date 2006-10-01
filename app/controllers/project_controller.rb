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
  def list
    @project_pages, @projects = paginate :projects, :per_page => 10
  end
  
  # Lists all clients
  def clientlist
    @client_pages, @clients = paginate :clients, :per_page => 10
  end
  
  # Shows detail of chosen project
  def show
    @project = Project.find(params[:id])
    @employee = Employee.find_all
  end
  
  # Shows detail of chosen client
  def showclient
    @client = Client.find(params[:id])
  end
  
  # Creates new instance of project
  def new
    @project = Project.new
    @client = Client.find_all
  end
  
  # Creates new instance of client
  def newclient
    @client = Client.new
  end
  
  # Create projectmembership
  def createpromem
    @project = Project.find(params[:project_id])
    @employees = Employee.find(params[:employee_id])
    @employees.each do |e|
      Projectmembership.create(:project_id => @project.id,
                               :employee_id => e.id)
      end
    flash[:notice] = 'Projectmember was created.'
    redirect_to :action => 'show' , :id => @project
  end

  # Add projectmanagement
  def addpromem
    @project = Project.find(params[:project_id])
    @promem = Projectmembership.find(params[:projectmembership_id])
    @promem.update_attributes(:projectmanagement => true)
    flash[:notice] = "#{@promem.employee.lastname} #{@promem.employee.firstname} was added to projectmanager."
    redirect_to :action => 'show' , :id => @project
  end
  
  # Remove projectmanagement
  def removepromem
    @project = Project.find(params[:project_id])
    @promem = Projectmembership.find(params[:projectmembership_id])
    @promem.update_attributes(:projectmanagement => false)
    flash[:notice] = "#{@promem.employee.lastname} #{@promem.employee.firstname} was removed from projectmanager."
    redirect_to :action => 'show' , :id => @project
  end
  
  # Destroy projectmembership
  def destroypromem
    @project = Project.find(params[:project_id])
    Projectmembership.find(params[:projectmembership_id]).destroy
    flash[:notice] = 'Projectmember was deleted.'
    redirect_to :action => 'show' , :id => @project
  end
  
  # Saves new client on db
  def createclient
    @client = Client.new(params[:client])
    if @client.save
      flash[:notice] = 'Client was successfully created.'
      redirect_to :action => 'clientlist'
    else
      render :action => 'newclient'
    end
  end
  
  # Saves new project on db
  def create
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
  def edit
    @project = Project.find(params[:id])
    @client = Client.find(:all)
  end
  
  # Shows the editpage of client
  def editclient
    @client = Client.find(params[:id])
  end
  
  
  # Stores the updated attributes of project
  def update
    @project = Project.find(params[:id])
    if @project.update_attributes(params[:project])
      flash[:notice] = 'Project was successfully updated.'
      redirect_to :action => 'show', :id => @project
    else
      render :action => 'edit'
    end
  end
  
  # Stores the updated attributes of client
  def updateclient
    @client = Client.find(params[:id])
    if @client.update_attributes(params[:client])
      flash[:notice] = 'Client was successfully updated.'
      redirect_to :action => 'clientlist', :id => @client
    else
      render :action => 'editclient'
    end
  end
  
  # Deletes the chosen project
  def destroy
    Project.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  # Deletes the chosen client
  def destroyclient
    Client.find(params[:id]).destroy
    redirect_to :action => 'clientlist'
  end
end
