class ProjecttimeController < WorktimeController

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
  
private

  def set_alltime_accounts
    @accounts = @worktime.employee.alltime_leaf_projects
  end
  
end