# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WorktimeController < ApplicationController
 
  include ApplicationHelper
  
  # Checks if employee came from login or from direct url.
  before_filter :authenticate

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :delete, :create, :update, :createPart, :deletePart ],
         :redirect_to => { :action => 'list' }
         
  hide_action :detailAction                
         
  FINISH = 'Abschliessen'       
   
  def index
    list
  end 
  
  def list
    redirect_to :controller => 'evaluator', :action => userEvaluation, :clear => 1
  end
  
  # Shows the add time page.
  def add
    createDefaultWorktime   
    setWorktimeAccount
    setAccounts 
    renderGeneric :action => 'add'  
  end  
    
  # Stores the new time the data on DB.
  def create
    setNewWorktime
    @worktime.employee = @user    
    setWorktimeParams
    if @worktime.save      
      flash[:notice] = 'Die Arbeitszeit wurde erfasst'
      return if ! processAfterSave
      return listDetailTime if params[:commit] == FINISH        
      @worktime = @worktime.template
    end  
    setAccounts
    renderGeneric :action => 'add'
  end  
  
  # Shows the edit page for the selected time.
  def edit
    setWorktime   
    setAccounts
    renderGeneric :action => 'edit'
  end  
    
  # Update the selected worktime on DB.
  def update  
    setWorktime
    if @worktime.employee != @user
      return listDetailTime if @worktime.absence?
      session[:split] = WorktimeEdit.new(@worktime.clone)
      createPart
    else
      setWorktimeParams
      if @worktime.save
        flash[:notice] = 'Die Arbeitszeit wurde aktualisiert'
        return if ! processAfterSave
        listDetailTime
      else
        setAccounts
        renderGeneric :action => 'edit'
      end  
    end  
  end
  
  def confirmDelete
    setWorktime
    renderGeneric :action => 'confirmDelete'   
  end
  
  def delete
    setWorktime
    @worktime.destroy if @worktime.employee == @user
    flash[:notice] = 'Die Arbeitszeit wurde entfernt'
    listDetailTime
  end
  
  def view
    setWorktime
    renderGeneric :action => 'view'
  end  
  
  def split
    @split = session[:split]
    redirect_to :controller => 'projecttime', :action => 'add' if @split.nil?
    @worktime = @split.worktimeTemplate
    @accounts = @worktime.employee.projects
    renderGeneric :action => 'split'
  end
  
  def createPart
    @split = session[:split]
    params[:id] ? setWorktime : setNewWorktime 
    @worktime.employee = @user
    setWorktimeParams
    if @worktime.valid? && @split.addWorktime(@worktime)   
      if @split.complete? || (params[:commit] == FINISH && @split.class::INCOMPLETE_FINISH)
        @split.save
        session[:split] = nil
        flash[:notice] = 'Alle Arbeitszeiten wurden erfasst'
        listDetailTime
      else
        session[:split] = @split
        redirect_to evaluation_detail_params.merge!({:action => 'split'})
      end     
    else
      @accounts = @worktime.employee.projects
      renderGeneric :action => 'split'
    end         
  end
  
  def deletePart
    session[:split].removeWorktime(params[:part_id].to_i)
    redirect_to evaluation_detail_params.merge!({:action => 'split'})
  end  

  # no action, may overwrite in subclass
  def detailAction
    'details'
  end
  
protected

  def createDefaultWorktime
    period = session[:period]
    setNewWorktime
    @worktime.from_start_time = Time.now.change(:hour => DEFAULT_START_HOUR)
    @worktime.report_type = DEFAULT_REPORT_TYPE
    @worktime.work_date = (period && period.length == 1) ? period.startDate : Date.today
    @worktime.employee = @user   
  end
  
  def setWorktimeParams
    @worktime.attributes = params[:worktime]
    # Catch the exception from AR::Base
  rescue ActiveRecord::MultiparameterAssignmentErrors => ex
    # Iterarate over the exceptions and remove the invalid field components from the input
    ex.errors.each { |err| params[:worktime].delete_if { |key, value| key =~ /^#{err.attribute}/ } }
    # Recreate the Model with the bad input fields removed
    @worktime.attributes = params[:worktime]
    # remove manually as @worktime already had a valid work_date, we want an error to be thrown
    @worktime.work_date = nil 
  end
  
  def listDetailTime
    options = evaluation_detail_params
    options[:controller] = 'evaluator'
    options[:action] = detailAction
    if params[:evaluation].nil? 
      options[:evaluation] = userEvaluation
      options[:clear] = 1
      if session[:period].nil? || ! session[:period].include?(@worktime.work_date)
        period = Period.weekFor(@worktime.work_date)
        options[:start_date] = period.startDate
        options[:end_date] = period.endDate
      end  
    end
    redirect_to options 
  end
  
  def setWorktime
    @worktime = Worktime.find(params[:id])
  end
  
  # overwrite in subclass
  def setNewWorktime
    @worktime = nil
  end
  
  # overwrite in subclass
  def setWorktimeAccount    
  end
  
  # overwrite in subclass
  def setAccounts
    @accounts = nil 
  end
  
  # may overwrite in subclass
  def userEvaluation
    'userProjects'
  end
  
  # may overwrite in subclass
  # return whether normal proceeding should continue or another action was taken
  def processAfterSave
    true
  end
  
  def genericPath
    'worktime'
  end
 
end
