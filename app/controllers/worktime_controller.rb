# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WorktimeController < ApplicationController
 
  # Used for the method days_in_month.
  include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods  

  # Checks if employee came from login or from direct url.
  before_filter :authorize
  

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
 
  # Creates new instance.
  def newTime
    @worktime = Worktime.new
  end
  
  #List the time.
  def listTime
    @user_projectmemberships = @user.projectmemberships
  end
  
  # Shows the edit page for the selected time.
  def editTime
    @project = Project.find(params[:project_id])
    @worktime = Worktime.find(params[:worktime_id])
  end
  
  # Shows the addAbsence page.
  def addAbsence
    @absence = Absence.find(:all)
  end
  
  # Shows the addTime page.
  def addTime
    @project = Project.find(params[:project_id])
  end
  
  # Update the selected worktime on DB.
  def updateTime
    @worktime = Worktime.find(params[:worktime_id])
    @project = Project.find(params[:project_id])
    start_time_hour = params[:worktime_from_start_time_hour]
    start_time_minute = params[:worktime_from_start_time_minute]
    end_time_hour = params[:worktime_to_end_time_hour]
    end_time_minute = params[:worktime_to_end_time_minute]
    params[:worktime][:employee_id] = @user.id 
    params[:worktime][:project_id] = @project.id
    params[:worktime][:from_start_time] = "{#{start_time_hour}:#{start_time_minute}}"
    params[:worktime][:to_end_time] = "{#{end_time_hour}:#{end_time_minute}}"
    
    if params[:worktime][:report_type]=='start_stop_day'
      hours_start = start_time_hour.to_f + (start_time_minute.to_f/60)
      hours_end = end_time_hour.to_f + (end_time_minute.to_f/60)
      if hours_end-hours_start > 0
        params[:worktime][:hours] = hours_end-hours_start
        @worktime.update_attributes(params[:worktime])
        flash[:notice] = 'Item was successfully updated.' 
        redirect_to :action => 'listTime'
      else
        flash[:notice] = 'Please select correct start and end time.'
        render :action => 'editTime'
      end
    else
      @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Item was successfully updated.'
      redirect_to :action => 'listTime'
    end
  end
    
  # Stores the new time the data on DB.
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
        Worktime.create(params[:worktime])
        flash[:notice] = 'Item was successfully created.' 
        redirect_to :action => 'listTime'
      else
        flash[:notice] = 'Please select correct start and end time.'
        render :action => 'addTime'
      end
    else Worktime.create(params[:worktime])
      flash[:notice] = 'Item was successfully updated.' 
      redirect_to :action => 'listTime'
    end
  end
  
  # Stores the new absence on DB. 
  def createAbsenceTime
    start_time_hour = params[:worktime_from_start_time_hour]
    start_time_minute = params[:worktime_from_start_time_minute]
    end_time_hour = params[:worktime_to_end_time_hour]
    end_time_minute = params[:worktime_to_end_time_minute]
    params[:worktime][:employee_id] = @user.id
    params[:worktime][:from_start_time] = "{#{start_time_hour}:#{start_time_minute}}"
    params[:worktime][:to_end_time] = "{#{end_time_hour}:#{end_time_minute}}"
    
   if params[:worktime][:report_type]=='start_stop_day'
      hours_start = start_time_hour.to_f + (start_time_minute.to_f/60)
      hours_end = end_time_hour.to_f + (end_time_minute.to_f/60)
      if hours_end-hours_start > 0
        params[:worktime][:hours] = hours_end-hours_start
        Worktime.create(params[:worktime])
        flash[:notice] = 'Item was successfully created.' 
        redirect_to :action => 'listTime'
      else
        flash[:notice] = 'Please select correct start and end time.'
        render :action => 'addTime'
      end
    else 
      Worktime.create(params[:worktime])
      flash[:notice] = 'Item was successfully updated.' 
      redirect_to :action => 'listTime'
    end 
  end
  
  
  # Store the request in the instances variables below.
  # They are needed to get data of the DB.
  def showUserProjectsPeriod
    setPeriodDates
  end
  
  def setPeriod(attributes)
    setPeriodDates
  end
  
  def getDate(attributes, prefix)
    "#{params[:worktime]['start(3i)']}-#{params[:worktime]['start(2i)']}-#{params[:worktime]['start(1i)']}"
  end
  
  # Shows all absences of user.
  def showUserAbsences
    @absences = Absence.find(:all)
  end
  
  
  # Store the request in the instances variables below.
  # They are needed to get data of the DB.
  def showUserAbsencesPeriod
    setPeriodDates
    @absences = Absence.find(:all)
  end
  
  # Shows user project detail of current week.
  def showDetailUserWeek
    @project = Project.find(params[:project_id])
    @times = Worktime.find(:all, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @project.id, @user.id, startCurrentWeek(Date.today), endCurrentWeek(Date.today)], :order => "work_date ASC")
  end
  
  # Shows user project detail of current month.
  def showDetailUserMonth
    @project = Project.find(params[:project_id])
    @times = Worktime.find(:all, :conditions => ["project_id = ? AND employee_id = ? AND  work_date BETWEEN ? AND ?", @project.id, @user.id, "#{Time.now.year}-#{Time.now.month}-01", "#{Time.now.year}-#{Time.now.month}-#{days_in_month(Time.now.month)}"], :order => "work_date ASC")
  end
  
  # Shows user project detail of current year.
  def showDetailUserYear
    @project = Project.find(params[:project_id])
    @times = Worktime.find(:all, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @project.id, @user.id, "#{Time.now.year}-01-01", "#{Time.now.year}-12-31"], :order => "work_date ASC")
  end
  
  # Shows user project deatil of selected period.
  def showDetailUserPeriod
    @project = Project.find(params[:project_id])
    @startdate = params[:startdate]
    @enddate = params[:enddate]
    @startdate_db = params[:startdate_db]
    @enddate_db = params[:enddate_db]
    @times = Worktime.find(:all, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", @project.id, @user.id, @startdate_db, @enddate_db ], :order => "work_date ASC")
  end
  
private
  
    # Sets the selected periodDates 
  def setPeriodDates
    @startdate = parseDate(params[:worktime], 'start')
    @enddate = parseDate(params[:worktime], 'end')
    @startdate_db = parseDate(params[:worktime], 'start')
    @enddate_db = parseDate(params[:worktime], 'end')
  end
  
end
