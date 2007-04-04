# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Worktime < ActiveRecord::Base
  
  include ReportType::Accessors
  
  belongs_to :employee
  belongs_to :absence   
  belongs_to :project
  
  validates_presence_of :work_date, :message => "Das Datum ist ung&uuml;ltig"
  validates_presence_of :employee_id, :message => "Ein Mitarbeiter muss vorhanden sein"
  
  before_validation DateFormatter.new('work_date')
  before_validation :store_hours
    
  H_M = /^(\d*):([0-5]\d)/
      
  def account
    nil
  end
  
  def account_id
    nil
  end
  
  def account_id=(value)
    
  end
  
  def self.account_label
    ''
  end
  
  def self.label
    'Arbeitszeit'
  end
  
  def hours=(value)
    if md = H_M.match(value.to_s)
      value = md[1].to_i + md[2].to_i / 60.0
    end
    write_attribute 'hours', value.to_f
  end
  
  def from_start_time=(value)
    write_converted_time 'from_start_time', value
  end
  
  def to_end_time=(value)
    write_converted_time 'to_end_time', value
  end
      
  def absence?
    false
  end
  
  def startStop?
    report_type.startStop?
  end
  
  def template(newWorktime = nil)
    newWorktime ||= self.class.new
    newWorktime.from_start_time = Time.now.change(:hour => 8)
    newWorktime.report_type = report_type
    newWorktime.work_date = work_date
    newWorktime.account_id = account_id
    newWorktime.billable = billable
    return newWorktime
  end
  
  def copyTimesFrom(other)
    self.report_type = other.report_type
    other.report_type.copy_times(other, self)
  end
  
  def timeString
    report_type.timeString(self)
  end
    
  def validate
    report_type.validate_worktime self
    project.validate_worktime self if project_id
  end
  
  def store_hours
    if startStop? && from_start_time && to_end_time
      self.hours = (to_end_time.seconds_since_midnight - from_start_time.seconds_since_midnight) / 3600.0
    end
  end

  def self.sumWorktime(period, absences)
    condArray = [ (absences ? 'absence_id' : 'project_id') + ' IS NOT NULL ' ]
    if period
      condArray[0] += " AND work_date BETWEEN ? AND ?"
      condArray.push period.startDate, period.endDate
    end
    self.sum(:hours, :conditions => condArray).to_f
  end
  
  def controller
    self.class.name.downcase
  end
  
private

  def write_converted_time(attribute, value)
    value = value.change(:sec => 0) if value.kind_of? Time
    if value.kind_of?(String) && ! (value =~ H_M) 
      if value.size > 0 && value =~ /^\d*\.?\d*$/
        value = value.to_i.to_s + ':' + ((value.to_f - value.to_i) * 60).to_i.to_s
      else
        value = nil
      end    
    end    
    write_attribute attribute, value
  end
  
end
