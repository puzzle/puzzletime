class AttendancetimeController < WorktimeController 
    
  verify :method => :post,
         :only => [ :autoStartStop, :startNow, :endNow ],
         :redirect_to => { :action => :list }
         
  before_filter :authenticate, :except => [:autoStartStop] 
  
  SPLIT = 'Aufteilen'     
           
  def autoStartStop
    @user = Employee.login(params[:user], params[:pwd])
    if @user 
      if @user.auto_start_time 
        attendance = stopAttendance
        startAttendance if attendance && attendance.work_date != Date.today
      else 
        startAttendance
      end   
    else  
      flash[:notice] = "Ung&uuml;ltige Benutzerdaten\n"
    end  
    render :text => flash[:notice]
  end         
  
  def start
    return if autoStartExists true, "Es wurde bereits eine fr&uuml;here Anwesenheit gestartet"
    startAttendance
    list
  end
  
  def stop
    return if autoStartExists(false, "Keine offene Anwesenheit vorhanden")
    attendance = stopAttendance
    if attendance then splitAttendance attendance
    else list
    end
  end  
  
  def splitAttendance(attendance = nil)
    attendance ||= setWorktime
    session[:split] = AttendanceSplit.new(attendance)
    redirect_to evaluation_detail_params.merge!({:action => 'split'})
  end
  
  def detailAction
    'attendanceDetails'
  end   
    
protected

  def setNewWorktime
    @worktime = Attendancetime.new   
  end  
  
  def startAttendance
    attendance = Attendancetime.new :employee => @user, 
                                    :report_type => AutoStartType::INSTANCE, 
                                    :work_date => Date.today, 
                                    :from_start_time => Time.now
    saveAttendance attendance, "Die Anwesenheit mit #timeString wurde erfasst\n"
  end
  
  def stopAttendance
    attendance = @user.auto_start_time
    attendance.to_end_time = attendance.work_date == Date.today ? Time.now : '23:59'
    attendance.report_type = StartStopType::INSTANCE
    attendance.store_hours
    if attendance.hours < 0.0166
      flash[:notice] = "Anwesenheiten unter einer Minute werden nicht erfasst\n"
      attendance.destroy
      @user.auto_start_time(true)
    else  
      saveAttendance attendance, "Die Anwesenheit von #timeString wurde gespeichert\n"
    end  
  end
  
  def autoStartExists(expected, msg)
    abort = (! @user.auto_start_time.nil?) == expected
    if abort
      flash[:notice] = msg
      list
    end
    abort  
  end
  
  def saveAttendance(attendance, msg)
    if attendance.save
      flash[:notice] = msg.sub('#timeString', attendance.timeString)
    else
      flash[:notice] = 'Die Anwesenheit konnte nicht gespeichert werden:\n'
      attendance.errors.each { |attr, msg| flash[:notice] += "<br/> - " + msg + "\n"}
    end    
    @user.auto_start_time(true) 
    attendance
  end

  def processAfterSave
    if params[:commit] == SPLIT
      splitAttendance @worktime
      return false
    end  
    true
  end
  
end