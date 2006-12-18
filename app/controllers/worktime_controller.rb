# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WorktimeController < ApplicationController
 
  # Checks if employee came from login or from direct url.
  before_filter :authenticate

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :deleteTime, :createTime, :updateTime, :updateProject ],
         :redirect_to => { :action => :listTime }
   
  #List the time.
  def listTime
    eval = 'userProjects'
    if @worktime != nil && @worktime.absence? 
      @user.absences(true)      #true forces reload
      eval = 'userAbsences'
    end  
    redirect_to :controller => 'evaluator', :action => eval
  end
  
  # Shows the edit page for the selected time.
  def editTime    
    @worktime = Worktime.find(params[:id])
    @accounts = @worktime.absence? ? Absence.list : @user.projects    
  end
  
  # Shows the addAbsence page.
  def addAbsence
    createDefaultWorktime
    @accounts = Absence.list
    render :action => 'addTime'
  end
  
  # Shows the addTime page.
  def addTime
    createDefaultWorktime   
    if params.has_key? :absence_id
      @accounts = Absence.list
      @worktime.absence_id = params[:absence_id] 
    else
      @accounts = @user.projects
      @worktime.project_id = params[:project_id] 
    end  
  end
  
  def confirmDeleteTime
    @worktime = Worktime.find(params[:id])
  end
  
  def deleteTime
    Worktime.destroy(params[:id])
    redirect_to :controller => 'evaluator', 
                :action => 'details', 
                :evaluation => params[:evaluation],
                :category_id => params[:category_id],
                :division_id => params[:division_id]
  end
    
  # Update the selected worktime on DB.
  def updateTime        
    parseTimes
    @worktime = Worktime.find(params[:worktime_id])
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
    if @worktime.save
      flash[:notice] = 'Time was successfully updated.'
      listDetailTime
    else
      render :action => 'editTime'
    end  
  end
    
  # Stores the new time the data on DB.
  def createTime
    parseTimes 
    begin
      @worktime = Worktime.new(params[:worktime])
    # Catch the exception from AR::Base
    rescue ActiveRecord::MultiparameterAssignmentErrors => ex
      # Iterarate over the exceptions and remove the invalid field components from the input
      ex.errors.each { |err| params[:worktime].delete_if { |key, value| key =~ /^#{err.attribute}/ } }
      # Recreate the Model with the bad input fields removed
      @worktime = Worktime.new(params[:worktime])      
    end
    if @worktime.save      
      flash[:notice] = 'Time was successfully added.'
      listDetailTime  
    else
      render :action => 'addTime'
    end  
  end
  
    # Show the change project page.
  def changeProject
    if @user.management
      @projects = Project.list
    else
      @projects = @user.managed_projects
    end  
    @worktime = Worktime.find(params[:worktime_id])
  end
  
  # Stores the changes on the DB.
  def updateProject
    @worktime = Worktime.find(params[:worktime_id])
    if @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Project was successfully changed'
      redirect_to :controller => 'evaluator', :action => 'overview', :evaluation => params[:evaluation]
    else
      render :action => 'changeWorktimeProject'
    end
  end
  
private

  #List the time.
  def listDetailTime
    eval = 'userProjects'
    if @worktime != nil && @worktime.absence? 
      @user.absences(true)      #true forces reload
      eval = 'userAbsences'
    end  
    if session[:period].nil?
      session[:period] = Period.weekFor(@worktime.work_date)
    end
    redirect_to :controller => 'evaluator', 
                :action => 'details', 
                :evaluation => eval, 
                :category_id => @user.id
  end

  def createDefaultWorktime
    @worktime = Worktime.new
    @worktime.report_type = Worktime::TYPE_HOURS_DAY
    period = session[:period]
    if period != nil && period.length == 1
      @worktime.work_date = period.startDate
    end  
  end
      
  def parseTimes
    params[:worktime][:employee_id] = @user.id
    if params[:worktime][:report_type] == Worktime::TYPE_START_STOP
      start_hour = params[:worktime_from_start_time_hour]
      start_minute = params[:worktime_from_start_time_minute]
      end_hour = params[:worktime_to_end_time_hour]
      end_minute = params[:worktime_to_end_time_minute]
      params[:worktime][:from_start_time] = "{#{start_hour}:#{start_minute}}"
      params[:worktime][:to_end_time] = "{#{end_hour}:#{end_minute}}"
      params[:worktime][:hours] = end_hour.to_f + (end_minute.to_f / 60) - start_hour.to_f - (start_minute.to_f / 60) 
    end
  end

end
