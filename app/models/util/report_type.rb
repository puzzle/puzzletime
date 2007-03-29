class ReportType

  include Comparable
  attr_reader :key, :name, :accuracy
  
protected
  
  def initialize(key, name, accuracy)
    @key = key
    @name = name
    @accuracy = accuracy
  end
  
public    
 
  def self.[](key)
    INSTANCES.detect {|type| type.key == key }
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

end

class StartStopType < ReportType
  INSTANCE = self.new 'start_stop_day', 'Start/Stop Zeit', 10
  
  def timeString(worktime)
    worktime.from_start_time.strftime(TIME_FORMAT) + ' - ' + 
      worktime.to_end_time.strftime(TIME_FORMAT) + 
      ' (' + ((worktime.hours*100).round / 100.0).to_s + ' h)'    
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

class HoursDayType < ReportType
  INSTANCE = self.new 'absolute_day', 'Stunden/Tag', 6
  
  def timeString(worktime)
    worktime.hours.to_s + ' h'
  end
end 

class HoursWeekType < ReportType
  INSTANCE = self.new 'week', 'Stunden/Woche', 4
  
  def timeString(worktime)
    worktime.hours.to_s + ' h in dieser Woche'
  end
end 

class HoursMonthType < ReportType
  INSTANCE = self.new 'month', 'Stunden/Monat', 2
  
  def timeString(worktime)
    worktime.hours.to_s + ' h in diesem Monat'
  end
end 


class ReportType    
  INSTANCES = [StartStopType::INSTANCE, 
               HoursDayType::INSTANCE,
               HoursWeekType::INSTANCE,
               HoursMonthType::INSTANCE]
end