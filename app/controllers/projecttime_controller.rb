class ProjecttimeController < WorktimeController

  def start
    running = runningTime
    if running
      running.description = params[:description]
      stopRunning running
    end  
    time = Projecttime.new
    time.project_id = params[:id]
    startRunning time
    if @user.running_attendance.nil?
      startRunning Attendancetime.new
    end
    redirect_to_running
  end
  
  def stop
    running = runningTime
    if running
      running.description = params[:description]
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
  
  def createDefaultWorktime
    super
    @worktime.attendance = @user.default_attendance
  end
  
  def setWorktimeAccount
    @worktime.setProjectDefaults(params[:account_id] || @user.default_project_id)
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
    if ! @worktime.attendance
      return true
    end
    attendance = @worktime.template Attendancetime.new
    attendance.employee_id = @worktime.employee_id
    attendance.copyTimesFrom @worktime
    if ! attendance.save
      @worktime.errors.add_to_base attendance.errors.full_messages.first
      setAccounts
      renderGeneric :action => 'add'
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