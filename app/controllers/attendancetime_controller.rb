class AttendancetimeController < WorktimeController

  def detailAction
    'attendanceDetails'
  end
    
protected

  def setNewWorktime
    @worktime = Attendancetime.new   
  end  

  def processAfterCreate
    if params[:commit] == 'Aufteilen'
      attendance = @worktime
      @worktime = attendance.template Projecttime.new
      @worktime.copyTimesFrom attendance
      @accounts = @user.projects
      renderGeneric :action => 'add'
      return false
    end  
    true
  end
  
end