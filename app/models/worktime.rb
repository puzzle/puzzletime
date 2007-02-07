# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Worktime < ActiveRecord::Base
  
  include ReportType::Accessors
  
  belongs_to :absence 
  belongs_to :employee
  belongs_to :project
  
  validates_presence_of :work_date, :message => "Das Datum ist ung&uuml;ltig"
  validates_presence_of :employee_id, :message => "Ein Mitarbeiter muss vorhanden sein"
  
  before_validation DateFormatter.new('work_date')
  before_validation :store_hours
    
  H_M = /^(\d*):([0-5]\d)/
      
  def account
    project ? project : absence
  end
  
  def hours=(value)
    if md = H_M.match(value.to_s)
      value = md[1].to_i + md[2].to_i / 60.0
    end
    write_attribute('hours', value.to_f)
  end
  
  def from_start_time=(value)
    write_attribute('from_start_time', string_to_time(value))
  end
  
  def to_end_time=(value)
    write_attribute('to_end_time', string_to_time(value))
  end
  
  def formatted_start_time
    formatted_time(from_start_time)
  end
  
  def formatted_end_time
    formatted_time(to_end_time)
  end
  
  def absence?
    absence_id != nil
  end
  
  def times?
    report_type == ReportType::START_STOP
  end
  
  def template
    newWorktime = Worktime.new
    newWorktime.from_start_time = Time.now.change(:hour => 8)
    newWorktime.report_type = report_type
    newWorktime.work_date = work_date
    newWorktime.project_id = project_id
    newWorktime.absence_id = absence_id
    newWorktime.billable = billable
    return newWorktime
  end
  
  def timeString
    case report_type
      when ReportType::START_STOP then formatted_start_time + ' - ' + formatted_end_time + 
                          ' (' + ((hours*100).round / 100.0).to_s + ' h)'
      when ReportType::HOURS_DAY then hours.to_s + ' h'
      when ReportType::HOURS_WEEK then hours.to_s + ' h in dieser Woche'
      when ReportType::MONTH then hours.to_s + ' h in diesem Monat'
    end
  end
  
  def validate
    if times?
      errors.add(:from_start_time, 'Die Anfangszeit ist ung&uuml;ltig') if ! from_start_time
      errors.add(:to_end_time, 'Die Endzeit ist ung&uuml;ltig') if ! to_end_time
      errors.add(:to_end_time, 'Die Endzeit muss nach der Startzeit sein') if from_start_time && 
          to_end_time && to_end_time <= from_start_time
    else
      errors.add(:hours, 'Stunden m&uuml;ssen positiv sein') if hours <= 0
    end
    project.validate_worktime self if project_id
  end
  
  def store_hours
    if times? && from_start_time && to_end_time
      self.hours = (to_end_time - from_start_time) / 3600.0
    end
  end
  
  def setProjectDefaults
    self.report_type = project.report_type if report_type < project.report_type
    self.billable = project.billable
  end
  
private

  def formatted_time(time)
    time ||= Time.now
    time.strftime("%H:%M")
  end

  def string_to_time(value)
    if value.kind_of?(String) && ! (value =~ H_M) 
      if value.size > 0 && value =~ /^\d*\.?\d*$/
        value = value.to_i.to_s + ':' + ((value.to_f - value.to_i) * 60).to_i.to_s
      else
        value = nil
      end    
    end
    value
  end
  
end
