# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WorktimeController < ApplicationController
 
  include ApplicationHelper
  
  # Checks if employee came from login or from direct url.
  before_filter :authenticate

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :delete, :create, :update ],
         :redirect_to => { :action => :list }
         
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
      return if ! processAfterCreate
      if params[:commit] != FINISH        
        @worktime = @worktime.template
        setAccounts
        renderGeneric :action => 'add'
      else
        options = { :controller => 'evaluator', 
                    :action     => detailAction, 
                    :evaluation => userEvaluation,
                    :clear => 1 }
        if session[:period].nil? || ! session[:period].include?(@worktime.work_date)
          period = Period.weekFor(@worktime.work_date)
          options[:start_date] = period.startDate
          options[:end_date] = period.endDate
        end
        redirect_to options 
      end
    else
      setAccounts
      renderGeneric :action => 'add'
    end  
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
    session[:edit] = nil
    return createWorktimeEdit if @worktime.employee != @user
    setWorktimeParams
    if @worktime.save
      flash[:notice] = 'Die Arbeitszeit wurde aktualisiert'
      redirect_to evaluation_detail_params.merge!({
                        :controller => 'evaluator',
                        :action => detailAction }) 
    else
      setAccounts
      renderGeneric :action => 'edit'
    end  
  end
  
  def createWorktimeEdit
    @edit = session[:edit]
    if @edit.nil?
      setWorktime
      @edit = WorktimeEdit.new(@worktime.clone)
    else  
      @worktime = @edit.worktimeTemplate
    end    
    setWorktimeParams
    if @worktime.valid?
      if @edit.addWorktime(@worktime)
        if @edit.incomplete?
          session[:edit] = @edit
          @worktime = @edit.worktimeTemplate
        else
          @edit.save
          session[:edit] = nil
          flash[:notice] = 'Die Arbeitszeit wurde angepasst'
          redirect_to evaluation_detail_params.merge!({
                        :controller => 'evaluator',
                        :action => detailAction }) 
          return              
        end
      end  
    end
    @accounts = @worktime.employee.projects 
    renderGeneric :action => 'worktimeEdit'
  end
 
  def confirmDelete
    setWorktime
    renderGeneric :action => 'confirmDelete'   
  end
  
  def delete
    setWorktime
    @worktime.destroy if @worktime.employee == @user
    flash[:notice] = 'Die Arbeitszeit wurde entfernt'
    redirect_to evaluation_detail_params.merge!({
                  :controller => 'evaluator', 
                  :action => detailAction})
  end
  
  def view
    setWorktime
    renderGeneric :action => 'view'
  end  
  
  # may overwrite in subclass
  def detailAction
    'details'
  end
  
protected

  def createDefaultWorktime
    setNewWorktime
    @worktime.from_start_time = Time.now.change(:hour => DEFAULT_START_HOUR)
    @worktime.report_type = DEFAULT_REPORT_TYPE
    period = session[:period]
    @worktime.work_date = (period != nil && period.length == 1) ?
       period.startDate : Date.today
  end
  
  def setWorktimeParams
    begin
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
  def processAfterCreate
    true
  end
  
  def genericPath
    'worktime'
  end
 
end
