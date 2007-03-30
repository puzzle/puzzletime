# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WorktimeController < ApplicationController
 
  include ApplicationHelper
  
  # Checks if employee came from login or from direct url.
  before_filter :authenticate

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :delete, :create, :update ],
         :redirect_to => { :action => :list }
         
  FINISH = 'Abschliessen'       
   
  def index
    list
  end 
  
  def list
    redirect_to :controller => 'evaluator', :action => userEvaluation
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
    setWorktime
    @worktime.employee = @user    
    setWorktimeParams
    if @worktime.save      
      flash[:notice] = 'Die Arbeitszeit wurde erfasst'
      if params[:commit] == 'Aufteilen'
        @worktime = @worktime.template Projecttime.new
        @accounts = @user.projects
        renderGeneric :action => 'add'
      elsif params[:commit] != FINISH        
        @worktime = @worktime.template
        setAccounts
        renderGeneric :action => 'add'
      else
        options = {:controller => 'evaluator', 
                   :action => (@worktime.kind_of?(Attendancetime) ? 'attendanceDetails' : 'details'), 
                   :evaluation => userEvaluation }
        if session[:period].nil? || 
            ! session[:period].include?(@worktime.work_date)
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
    @worktime = Worktime.find(params[:id])   
    setAccounts
    renderGeneric :action => 'edit'
  end  
    
  # Update the selected worktime on DB.
  def update  
    @worktime = Worktime.find(params[:id])
    return createWorktimeEdit if @worktime.employee != @user
    setWorktimeParams
    if @worktime.save
      flash[:notice] = 'Die Arbeitszeit wurde aktualisiert'
      redirect_to evaluation_detail_params.merge!({
                        :controller => 'evaluator',
                        :action => params[:return_action] }) 
    else
      setAccounts
      renderGeneric :action => 'edit'
    end  
  end
  
  def createWorktimeEdit
    @edit = session[:edit]
    if @edit.nil?
      @worktime = Worktime.find(params[:id])
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
                        :action => params[:return_action] }) 
          return              
        end
      end  
    end
    @accounts = @worktime.employee.projects 
    renderGeneric :action => 'worktimeEdit'
  end
 
  def confirmDelete
    @worktime = Worktime.find(params[:id])
    renderGeneric :action => 'confirmDelete'   
  end
  
  def delete
    worktime = Worktime.find(params[:id])
    worktime.destroy if worktime.employee == @user
    flash[:notice] = 'Die Arbeitszeit wurde entfernt'
    redirect_to evaluation_detail_params.merge!({
                  :controller => 'evaluator', 
                  :action => params[:return_action]})
  end
  
protected

  #List the time.
  def listDetailTime
    if session[:period].nil? || 
        (! @worktime.nil? && ! session[:period].include?(@worktime.work_date) )
      period = Period.weekFor(@worktime.work_date)
      @periodParam ||= {:start_date => period.startDate, :end_date => period.endDate}
    else
      @periodParam ||= {}   
    end
    redirect_to @periodParam.merge!({
                :controller => 'evaluator', 
                :action => 'details', 
                :evaluation => userEvaluation, 
                :category_id => @user.id })
  end

  def createDefaultWorktime
    setWorktime
    @worktime.from_start_time = Time.now.change(:hour => DEFAULT_START_HOUR)
    @worktime.report_type = DEFAULT_REPORT_TYPE
    period = session[:period]
    @worktime.work_date = (period != nil && period.length == 1) ?
       period.startDate : Date.today
  end
  
  # overwrite in subclass
  def setWorktime
    @worktime = nil
  end
  
  # overwrite in subclass
  def setWorktimeAccount
    
  end
  
  # overwrite in subclass
  def setAccounts
    @accounts = nil 
  end
  
  #overwrite in subclass
  def userEvaluation
    ''
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
  
  def genericPath
    'worktime'
  end

end
