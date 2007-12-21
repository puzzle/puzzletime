# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Worktime < ActiveRecord::Base
  
  include ReportType::Accessors
  include Conditioner
  extend Evaluatable
  
  belongs_to :employee
  belongs_to :absence   
  belongs_to :project
  
  validates_presence_of :work_date, :message => "Das Datum ist ung&uuml;ltig"
  validates_presence_of :employee_id, :message => "Ein Mitarbeiter muss vorhanden sein"
  
  before_validation DateFormatter.new('work_date')
  before_validation :store_hours
    
  H_M = /^(\d*):([0-5]\d)/

  ###############  ACCESSORS  ##################
  
  # account this worktime is booked for.
  # defined in subclasses, either Project or Absence    
  def account
    nil
  end
  
  # account id, default nil
  def account_id
  end
  
  # sets the account id.
  # overwrite in subclass
  def account_id=(value)    
  end
  
  # set the hours, either as number or as a string with the format
  # h:mm or h.dd (8:45 <-> 8.75)
  def hours=(value)
    if md = H_M.match(value.to_s)
      value = md[1].to_i + md[2].to_i / 60.0
    end
    write_attribute 'hours', value.to_f
  end
  
  # set the start time, either as number or as a string with the format
  # h:mm or h.dd (8:45 <-> 8.75)
  def from_start_time=(value)
    write_converted_time 'from_start_time', value
  end
  
  # set the end time, either as number or as a string with the format
  # h:mm or h.dd (8:45 <-> 8.75)
  def to_end_time=(value)
    write_converted_time 'to_end_time', value
  end
    
  # Returns a human readable String of the time information contained in this Worktime.  
  def timeString
    report_type.timeString(self)
  end
      
  def work_date
    # cache date to prevent endless string_to_date conversion
    @work_date ||= read_attribute(:work_date)
  end
  
  def work_date=(value)
    write_attribute(:work_date, value)
    @work_date = nil
  end
      
  ###################  TESTS  ####################    
      
  # Whether this Worktime is for an absence or not
  def absence?
    false
  end
  
  # Whether the report typ of this Worktime contains start and stop times
  def startStop?
    report_type.startStop?
  end
  
  # Whether this Worktime contains the passed attribute
  def hasAttribute?(attr)
    self.class.validAttributes.include? attr
  end
  
  ##################  HELPERS  ####################
  
  # Returns a copy of this Worktime with default values set
  def template(newWorktime = nil)
    newWorktime ||= self.class.new
    newWorktime.from_start_time = report_type.is_a?(StartStopType) ? 
                 to_end_time : Time.now.change(:hour => DEFAULT_START_HOUR)
    newWorktime.report_type = report_type
    newWorktime.work_date = work_date
    newWorktime.account_id = account_id
    newWorktime.billable = billable
    newWorktime.employee_id = employee_id
    return newWorktime
  end
  
  def copy_from(other)
    self.report_type      = other.report_type
    self.work_date        = other.work_date
    self.hours            = other.hours
    self.from_start_time  = other.from_start_time
    self.to_end_time      = other.to_end_time
  end
  
  # Copies the report_type and the time information from an other Worktime
  def copyTimesFrom(other)
    self.report_type = other.report_type
    other.report_type.copy_times(other, self)
  end

  # Validate callback before saving  
  def validate
    report_type.validate_worktime self
  end
  
  # Store hour information from start/stop times.
  def store_hours
    if startStop? && from_start_time && to_end_time
      self.hours = (to_end_time.seconds_since_midnight - from_start_time.seconds_since_midnight) / 3600.0
    end
    self.work_date ||= Date.today
  end
  
  def find_corresponding
    return nil if corresponding_type.nil?
    conditions = ["type = ? AND employee_id = ? AND work_date = ?",
                  corresponding_type.name, employee_id, work_date]
    if report_type.is_a? StartStopType              
      conditions_append(conditions, ['from_start_time = ? AND to_end_time = ?', from_start_time, to_end_time])              
    else
      conditions_append(conditions, ['hours = ?', hours])
    end
    Worktime.find(:first, :conditions => conditions)
  end
  
  def corresponding_type
    nil
  end
  
  # Name of the corresponding controller
  def controller
    self.class.name.downcase
  end
  
  # Returns an Array of the valid report types for this Worktime
  def report_types
    ReportType::INSTANCES
  end
  
  def to_s
    "#{"%.2f" % hours} h #{self.class.label} #{'f&uuml;r ' + account.label_verbose if account_id}"
  end
  
  ##################  CLASS METHODS   ######################  
  
  # Returns an Array of the valid attributes for this Worktime
  def self.validAttributes
    [:work_date, :hours, :from_start_time, :to_end_time, :employee_id, :report_type]
  end
    
  # label for the account class
  # overwrite in subclass
  def self.account_label
    ''
  end
  
  #######################  CLASS METHODS FOR EVALUATABLE  ####################
  
  # label for this worktime class
  def self.label
    'Arbeitszeit'
  end
  
  def self.worktimes
    self
  end
 
private

  # allow time formats such as 14, 1400, 14:00 and 14.0 (1430, 14:30, 14.5)
  def write_converted_time(attribute, value)
    value = value.change(:sec => 0) if value.kind_of? Time
    if value.kind_of?(String) && ! (value =~ H_M) 
      if value.size > 0 && value =~ /^\d*\.?\d*$/
        # military time: 1400
        if value.size > 2 && ! value.include?(?.)
          hour = value.to_i / 100
          value = hour.to_s + ':' + (value.to_i - hour * 100).to_s
        else
          value = value.to_i.to_s + ':' + ((value.to_f - value.to_i) * 60).to_i.to_s
        end  
      else
        value = nil
      end    
    end    
    write_attribute attribute, value
  end
  
end
