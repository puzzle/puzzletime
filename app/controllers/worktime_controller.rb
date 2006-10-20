# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WorktimeController < ApplicationController
  
  # Checks if employee came from login or from direct url
  before_filter :authorize
  

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
  # Creates new instance
  def newTime
    @worktime = Worktime.new
  end
  
  #List the time
  def listTime
    @user_projectmemberships = @user.projectmemberships
  end
                
  # Shows the addTime or the addAbsence page   
  def addTime
    if params.has_key?(:project_id)
      @project = Project.find(params[:project_id])
    else
      @absence = Absence.find(:all)
    end
  end
  
  # Stores the data on DB 
  def createTime
    start_time_hour = params[:worktime_from_start_time_hour]
    start_time_minute = params[:worktime_from_start_time_minute]
    end_time_hour = params[:worktime_to_end_time_hour]
    end_time_minute = params[:worktime_to_end_time_minute]
    params[:worktime][:employee_id] = @user.id 
    params[:worktime][:project_id] = params[:project_id]
    params[:worktime][:from_start_time] = "{#{start_time_hour}:#{start_time_minute}}"
    params[:worktime][:to_end_time] = "{#{end_time_hour}:#{end_time_minute}}"
    
    if params[:worktime][:report_type]=='start_stop_day'
      hours_start = start_time_hour.to_f + (start_time_minute.to_f/60)
      hours_end = end_time_hour.to_f + (end_time_minute.to_f/60)
      if hours_end-hours_start > 0
        params[:worktime][:hours] = hours_end-hours_start
        worktime = Worktime.create(params[:worktime])
        flash[:notice] = 'Item was successfully created.' 
        redirect_to :action => 'listTime'
      else
        flash[:notice] = 'Please select correct start and end time.'
        render :action => 'addTime'
      end
    end
  end
  
  # Store the request in the instances variables below.
  # They are needed to get data of the DB.
  def showUserProjectsPeriod
    @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
  end
  
  # Shows all absences of user
  def showUserAbsences
    @absences = Absence.find(:all)
  end
  
  
  # Store the request in the instances variables below.
  # They are needed to get data of the DB.
  def showUserAbsencesPeriod
    @startdate ="#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"      
    @enddate = "#{params[:worktime]['end(3i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(1i)']}"
    @startdate_db = "#{params[:worktime]['start(1i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(3i)']}"      
    @enddate_db = "#{params[:worktime]['end(1i)']}-#{params[:worktime]['end(2i)']}-#{params[:worktime]['end(3i)']}"
    @absences = Absence.find(:all)
  end
end
