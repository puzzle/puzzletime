class Attendance
  
  attr_reader :time, :worktimes
  
  def initialize(time)
    @time = time
    @worktimes = []
    time.project_id = DEFAULT_PROJECT_ID
    time.description = 'Präsenzzeit'
  end
  
  def addWorktime(worktime)
    @worktimes.push(worktime)
  end
  
  def removeWorktime(index)
    @worktimes.delete_at(index)
  end

  def worktimeTemplate
    worktime = lastWorktime.template
    worktime.hours = remainingHours
    worktime.from_start_time = nextStartTime
    worktime.to_end_time = time.to_end_time
    return worktime
  end

  def incomplete?
    remainingHours > 0
  end
  
  def save
    if incomplete?
      time.hours = remainingHours
      time.save
    end
    worktimes.each { |wtime|
        wtime.save }
  end
  
private
  
  def remainingHours
    time.hours - worktimes.inject(0) {|sum, time| sum + time.hours}
  end
  
  def nextStartTime
    worktimes.empty? ? 
      time.from_start_time :
      worktimes.last.to_end_time    
  end
  
  def lastWorktime
    worktimes.empty? ? time : worktimes.last
  end
  
end