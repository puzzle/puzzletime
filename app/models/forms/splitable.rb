class Splitable

  INCOMPLETE_FINISH = true
  SUBMIT_BUTTONS = nil

  attr_reader :original, :worktimes
  
  def initialize(original)
    @original = original
    @worktimes = []
  end
  
  def addWorktime(worktime)
    if original.report_type > HoursWeekType::INSTANCE && worktime.work_date != original.work_date
      worktime.work_date = original.work_date
      worktime.errors.add(:work_date, 'Das Datum kann nicht geändert werden')
      return false
    end
    @worktimes.push(worktime)
  end
  
  def removeWorktime(index)
    @worktimes.delete_at(index) if @worktimes[index].new_record?
  end

  def worktimeTemplate
    worktime = lastWorktime.template Projecttime.new
    worktime.hours = remainingHours
    worktime.from_start_time = nextStartTime
    worktime.to_end_time = original.to_end_time
    worktime.project_id ||= worktime.employee.default_project_id
    worktime
  end
    
  def complete?
    remainingHours < 0.00001     # we are working with floats: use delta
  end
  
  def save
    worktimes.each { |wtime|  wtime.save }
  end
  
  def page_title
    'Aufteilen'
  end
  
  def empty?
    worktimes.empty?
  end
  
protected
  
  def remainingHours
    original.hours - worktimes.inject(0) {|sum, time| sum + time.hours}
  end
  
  def nextStartTime
    worktimes.empty? ? 
      original.from_start_time :
      worktimes.last.to_end_time    
  end
  
  def lastWorktime
    worktimes.empty? ? original : worktimes.last
  end
  
end