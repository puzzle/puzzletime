class AttendancetimeController < WorktimeController

  before_action :authenticate, except: [:autoStartStop]

  SPLIT = 'Aufteilen'

  def autoStartStop
    @user = Employee.login(params[:user], params[:pwd])
    if @user
      now = Time.now
      if @user.running_attendance
        attendance = stopRunning(runningTime, now)
        if attendance && @user.running_project
          stopRunning @user.running_project, now
        end
        startRunning(Attendancetime.new, now) if attendance && attendance.work_date != Date.today
      else
        startRunning Attendancetime.new, now
      end
    else
      flash[:notice] = "Ung&uuml;ltige Benutzerdaten.\n"
    end
    render text: flash[:notice]
  end

  # called from running
  def start
    if runningTime
      flash[:notice] = 'Es wurde bereits eine fr&uuml;here Anwesenheitszeit gestartet.'
    else
      startRunning Attendancetime.new
    end
    redirect_to :back
  end

  # called from running
  def stop
    attendance = runningTime
    if attendance
      now = Time.now
      stopRunning attendance, now
      project = @user.running_project
      if project
        project.description = params[:description] if params[:description]
        stopRunning project, now
      elsif !Projecttime.where('type = ? AND employee_id = ? AND work_date = ? AND to_end_time = ?',
                               'Projecttime', @user.id, attendance.work_date, attendance.to_end_time).exist?
        splitAttendance attendance
        return
      end
    else
      flash[:notice] = 'Keine offene Anwesenheit vorhanden.'
    end
    redirect_to :back
  end

  def splitAttendance(attendance = nil)
    attendance ||= setWorktime
    session[:split] = AttendanceSplit.new(attendance)
    redirect_to evaluation_detail_params.merge!(action: 'split')
  end

  def detailAction
    'attendanceDetails'
  end

  protected

  def setNewWorktime
    @worktime = Attendancetime.new
  end

  def setWorktimeDefaults
    @worktime.projecttime = @user.default_attendance
  end

  def autoStartExists(expected, msg)
    abort = (runningTime) == expected
    if abort
      flash[:notice] = msg
      list
    end
    abort
  end

  def processAfterSave
    if params[:commit] == SPLIT
      splitAttendance @worktime
      return false
    end
    true
  end

  def update_corresponding?
    params[:worktime][:projecttime].to_i != 0
  end

  def runningTime(reload = false)
    @user.running_attendance(reload)
  end

end
