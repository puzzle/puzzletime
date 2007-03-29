class Attendance < Splitable
  
  def initialize(time)
    super(time)
    original.project_id = DEFAULT_PROJECT_ID
    original.description = 'Präsenzzeit'
    original.billable = false
  end
    
  def save
    if incomplete?
      original.hours = remainingHours
      if ! worktimes.empty? && original.report_type == StartStopType::INSTANCE
        original.report_type = HoursDayType::INSTANCE
      end
      original.save
    end
    super
  end
  
end