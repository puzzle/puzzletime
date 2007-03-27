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
      if ! worktimes.empty? && original.report_type == ReportType::START_STOP
        original.report_type = ReportType::HOURS_DAY
      end
      original.save
    end
    super
  end
  
end