class ProjecttimeController < WorktimeController
    
   before_filter :load_old_projecttime, :only => [:update]
    
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
  
  def load_old_projecttime
    if params[:attendance]
      @old_projecttime = Projecttime.find(params[:id])
    end
  end
  
  def processAfterCreate
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
  
  def processAfterUpdate
    if @worktime.attendance
      
    end
    true
  end
  
end