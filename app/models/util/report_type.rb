class ReportType

  include Comparable
  
  attr_reader :key, :name, :accuracy
  
  START_STOP = false
  
  def self.[](key)
  	ALL_INSTANCES.each {|type| return type if type.key == key }
  end
  
  def to_s
    key
  end 
  
  def <=>(other)
    accuracy <=> other.accuracy
  end
  
  def validate_worktime(worktime)
    worktime.errors.add(:hours, 'Stunden m&uuml;ssen positiv sein') if worktime.hours <= 0
  end
  
  def copy_times(source, target)
    target.hours = source.hours
  end
  
  def startStop?
    self.class::START_STOP
  end
  
  def dateString(date)
    date.strftime(LONG_DATE_FORMAT)
  end
  
  module Accessors
    def report_type
      type = read_attribute('report_type')
      type.is_a?(String) ? ReportType[type] : type
    end
    
    def report_type=(type)
      type = type.key if type.is_a? ReportType
      write_attribute('report_type', type)
    end    
  end
  
  protected
  
  def initialize(key, name, accuracy)
    @key = key
    @name = name
    @accuracy = accuracy
  end
  
  def roundedHours(worktime)
    number = (Float(worktime.hours) * (100)).round.to_f / 100
    number = "%01.2f" % number
    parts = number.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1'")
    parts.join('.')
  end
  
end

class StartStopType < ReportType
  INSTANCE = self.new 'start_stop_day', 'Von/Bis Zeit', 10
  START_STOP = true
  
  def timeString(worktime)
    worktime.from_start_time.strftime(TIME_FORMAT) + ' - ' + 
      worktime.to_end_time.strftime(TIME_FORMAT) + 
      ' (' + roundedHours(worktime) + ' h)'    
  end
  
  def copy_times(source, target)
    super source, target
    target.from_start_time = source.from_start_time
    target.to_end_time = source.to_end_time
  end
  
  def validate_worktime(worktime)
    if ! worktime.from_start_time
      worktime.errors.add(:from_start_time, 'Die Anfangszeit ist ung&uuml;ltig') 
    end
    if ! worktime.to_end_time
      worktime.errors.add(:to_end_time, 'Die Endzeit ist ung&uuml;ltig')
    end
    if worktime.from_start_time && worktime.to_end_time && 
       worktime.to_end_time <= worktime.from_start_time
      worktime.errors.add(:to_end_time, 'Die Endzeit muss nach der Startzeit sein') 
    end
  end
end 

class AutoStartType < StartStopType
  INSTANCE = self.new 'auto_start', 'Von/Bis offen', 12
  
  def timeString(worktime)
    'Start um ' + worktime.from_start_time.strftime(TIME_FORMAT)
  end
  
  def validate_worktime(worktime)
    # set defaults
    worktime.work_date = Date.today
    worktime.hours = 0
    worktime.to_end_time = nil
    # validate
    if ! worktime.from_start_time
      worktime.errors.add(:from_start_time, 'Die Anfangszeit ist ung&uuml;ltig') 
    end
    existing = worktime.employee.send("running_#{worktime.class.name[0..-5].downcase}".to_sym) 
    if existing && existing != worktime
      worktime.errors.add(:employee_id, "Es wurde bereits eine offene #{worktime.class.label} erfasst")
    end
  end
end

class HoursDayType < ReportType
  INSTANCE = self.new 'absolute_day', 'Stunden/Tag', 6
  
  def timeString(worktime)
    roundedHours(worktime) + ' h'
  end
end 

class HoursWeekType < ReportType
  INSTANCE = self.new 'week', 'Stunden/Woche', 4
  
  def timeString(worktime)
    roundedHours(worktime) + ' h in dieser Woche'
  end
  
  def dateString(date)
    date.strftime('W %V, %Y')
  end
end 

class HoursMonthType < ReportType
  INSTANCE = self.new 'month', 'Stunden/Monat', 2
  
  def timeString(worktime)
    roundedHours(worktime) + ' h in diesem Monat'
  end
  
  def dateString(date)
    date.strftime('%m.%Y')
  end
end 


class ReportType    
  INSTANCES = [StartStopType::INSTANCE, 
               HoursDayType::INSTANCE,
               HoursWeekType::INSTANCE,
               HoursMonthType::INSTANCE]
  ALL_INSTANCES = INSTANCES + [AutoStartType::INSTANCE]
end