class ReportType

  include Comparable
  attr_reader :key, :name, :accuracy
  
private  
  def initialize(key, name, accuracy)
    @key = key
    @name = name
    @accuracy = accuracy
  end
  
public  
  
  START_STOP = new('start_stop_day', 'Start/Stop Zeit', 10)
  HOURS_DAY = new('absolute_day', 'Stunden/Tag', 6)
  HOURS_WEEK = new('week', 'Stunden/Woche', 4)
  HOURS_MONTH = new('month', 'Stunden/Monat', 2)
  
  INSTANCES = [START_STOP, HOURS_DAY, HOURS_WEEK, HOURS_MONTH]
  
  def self.[](key)
    INSTANCES.detect {|type| type.key == key }
  end
  
  def to_s
    key
  end 
  
  def <=>(other)
    accuracy <=> other.accuracy
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