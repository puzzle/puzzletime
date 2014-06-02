# encoding: utf-8

class AttendancetimesController < WorktimesController

  skip_before_action :authenticate, only: [:auto_start_stop]

  SPLIT = 'Aufteilen'

  def auto_start_stop
    @user = Employee.login(params[:user], params[:pwd])
    if @user
      now = Time.zone.now
      if @user.running_attendance
        attendance = stop_running(running_time, now)
        if attendance && @user.running_project
          stop_running @user.running_project, now
        end
        start_running(Attendancetime.new, now) if attendance && attendance.work_date != Date.today
      else
        start_running Attendancetime.new, now
      end
    else
      flash[:notice] = "Ungültige Benutzerdaten.\n"
    end
    render text: flash[:notice]
  end

  # called from running
  def start
    if running_time
      flash[:notice] = 'Es wurde bereits eine frühere Anwesenheitszeit gestartet.'
    else
      start_running Attendancetime.new
    end
    redirect_to controller: 'worktimes', action: 'running'
  end

  # called from running
  def stop
    attendance = running_time
    if attendance
      now = Time.zone.now
      stop_running attendance, now
      project = @user.running_project
      if project
        project.description = params[:description] if params[:description]
        project.ticket = params[:ticket] if params[:ticket]
        stop_running project, now
      elsif !Projecttime.where('type = ? AND employee_id = ? AND work_date = ? AND to_end_time = ?',
                               'Projecttime', @user.id, attendance.work_date, attendance.to_end_time).exists?
        split_attendance attendance
        return
      end
    else
      flash[:notice] = 'Keine offene Anwesenheit vorhanden.'
    end
    redirect_to controller: 'worktimes', action: 'running'
  end

  def split_attendance(attendance = nil)
    attendance ||= set_worktime
    session[:split] = AttendanceSplit.new(attendance)
    redirect_to evaluation_detail_params.merge!(action: 'split')
  end

  def detail_action
    'attendance_details'
  end

  protected

  def set_new_worktime
    @worktime = Attendancetime.new
  end

  def set_worktime_defaults
    @worktime.projecttime = @user.default_attendance
  end

  def auto_start_exists(expected, msg)
    abort = (running_time) == expected
    if abort
      flash[:notice] = msg
      list
    end
    abort
  end

  def process_after_save
    if params[:commit] == SPLIT
      split_attendance @worktime
      return false
    end
    true
  end

  def update_corresponding?
    params[:worktime][:projecttime].to_i != 0
  end

  def running_time(reload = false)
    @user.running_attendance(reload)
  end

  def model_params
    params.require(:worktime).permit(
      :report_type, :work_date, :hours,
      :from_start_time, :to_end_time)
  end
end
