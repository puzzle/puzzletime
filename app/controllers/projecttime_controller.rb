class ProjecttimeController < WorktimeController
    
protected

  def setNewWorktime
    @worktime = Projecttime.new   
  end
  
  def setWorktimeAccount
    @worktime.setProjectDefaults params[:account_id]
  end

  def setAccounts    
    @accounts = @worktime.employee.projects 
  end  
  
  def processAfterSave
    if @worktime.attendance
      attendance = @worktime.template Attendancetime.new
      attendance.employee_id = @worktime.employee_id
      attendance.copyTimesFrom @worktime
      if ! attendance.save
        @worktime.errors.add_to_base attendance.errors.full_messages.first
        setAccounts
        renderGeneric :action => 'add'
        return false
      end  
    end
    true
  end
end