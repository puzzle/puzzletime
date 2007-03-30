class AttendancetimeController < WorktimeController
  
protected

  def setWorktime
    @worktime = Attendancetime.new   
  end

  def userEvaluation
    'userProjects'
  end
  
end