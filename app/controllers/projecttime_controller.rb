# encoding: utf-8

class ProjecttimeController < WorktimeController

  def start
    running = runningTime
    now = Time.now
    if running
      running.description = params[:description]
      running.ticket = params[:ticket]
      stopRunning running, now
    end
    time = Projecttime.new
    time.project_id = params[:id]
    startRunning time, now
    if @user.running_attendance.nil?
      startRunning Attendancetime.new, now
    end
    redirect_to_running
  end

  def stop
    running = runningTime
    if running
      running.description = params[:description]
      running.ticket = params[:ticket]
      stopRunning running
    else
      flash[:notice] = 'Zur Zeit läuft kein Projekt'
    end
    redirect_to_running
  end

  protected

  def setNewWorktime
    @worktime = Projecttime.new
  end

  def setWorktimeDefaults
    @worktime.setProjectDefaults(params[:account_id] || @user.default_project_id) unless @worktime.project_id
    @worktime.attendance = @user.default_attendance
  end

  def setAccounts(all = false)
    if params[:other]
      @accounts = Project.leaves
    elsif all
      set_alltime_accounts
    else
      setProjectAccounts
      set_alltime_accounts unless @accounts.include? @worktime.project
    end
  end

  def update_corresponding?
    params[:worktime][:attendance].to_i != 0
  end

  def processAfterCreate
    unless @worktime.attendance
      return true
    end
    attendance = @worktime.template Attendancetime.new
    attendance.employee_id = @worktime.employee_id
    attendance.copyTimesFrom @worktime
    unless attendance.save
      @worktime.errors.add_to_base attendance.errors.full_messages.first
      setAccounts
      setExisting
      renderGeneric action: 'add'
      return false
    end
    true
  end

  def runningTime(reload = false)
    @user.running_project(reload)
  end

  private

  def set_alltime_accounts
    @accounts = @worktime.employee.alltime_leaf_projects
  end

end
