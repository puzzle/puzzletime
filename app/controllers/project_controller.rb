# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ProjectController < ApplicationController
  
  include ManageModule
  helper :worktime
  
  # Checks if employee came from login or from direct url.
  before_filter :authenticate
  before_filter :authorize, :only => [ :delete, :confirmDelete ]

  def list
    if @user.management? then super 
    else listManagedProjects   
    end
  end
  
  def listManagedProjects
    @entry_pages = Paginator.new self, @user.managed_projects.count, NO_OF_OVERVIEW_ROWS, params[:page]
    @entries = @user.managed_projects.find(:all, 
                          :limit => @entry_pages.items_per_page,
                          :offset => @entry_pages.current.offset)
    renderManage :action => 'list'   
  end
  
  def create
    super
    if @entry.errors.empty?
      # set current user as project manager
      Projectmembership.create(:project_id => @entry.id,
                               :employee_id => @user.id,
                               :projectmanagement => true)         
      @user.managed_projects(true)   
      @user.projects(true)                              
    end  
  end
  
  ####### helper methods, not actions ##########
    
  def modelClass
    Project
  end  
  
  def listActions
    [['Mitarbeiter', 'projectmembership', 'list']]
  end
  
  def editFields
    [[:name, 'Name'], 
     [:client, 'Kunde'],
     [:description, 'Beschreibung']]
  end
  
  def formatColumn(attribute, value)
    return value.slice(0..40) + (value.size > 40 ? '...' : '') if :description == attribute
    super attribute, value
  end
  
  def authorize
    authenticate
    unless @user.managed_projects.collect{|p| p.id.to_s}.include?(params[:id])
      super
    end
  end
  
protected
      
  def groupClass
    Client
  end
  
  def initFormData
    @clients = Client.list
    @entry.client_id = params[:group_id] if @entry.client_id.nil? && params[:group_id]
  end
  
end
