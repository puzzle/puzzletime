# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ProjectController < ApplicationController
  
  include ManageModule
  
  # Checks if employee came from login or from direct url.
  before_filter :authenticate
  before_filter :authorize, :only => [ :add, :create, :delete, :confirmDelete ]

  def list
    if @user.management then super 
    else listManagedProjects   
    end
  end
  
  def create
    super
    if @entry.errors.empty?
      # set current user as project manager
      Projectmembership.create(:project_id => @entry.id,
                               :employee_id => @user.id,
                               :projectmanagement => true)                 
    end  
  end
    
  def modelClass
    Project
  end  
  
  def listActions
    [['Mitarbeiter', 'projectmembership', 'list']]
  end
  
protected
      
  def groupClass
    Client
  end
  
  def initFormData
    @clients = Client.list
    @entry.client_id = params[:group_id] if @entry.client_id.nil? && params[:group_id]
  end
  
private  

  def listManagedProjects
    @project_pages = Paginator.new self, @user.managed_projects.count, NO_OF_OVERVIEW_ROWS, params[:page]
    @projects = @user.managed_projects.find(:all, 
                          :limit => @project_pages.items_per_page,
                          :offset => @project_pages.current.offset)
    render :action => '../manage/list'   
  end
  
end
