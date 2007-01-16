# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Worktime < ActiveRecord::Base
  
  # All dependencies between the models are listed below.
  belongs_to :absence 
  belongs_to :employee
  belongs_to :project
  
  validates_presence_of :work_date, :message => "is invalid"
  
  before_validation DateFormatter.new('work_date')
  before_validation :store_hours
    
  TYPE_START_STOP = 'start_stop_day'
  TYPE_HOURS_DAY = 'absolute_day'
  TYPE_HOURS_WEEK = 'week'
  TYPE_HOURS_MONTH = 'month'
  
  H_M = /(\d*):([0-5]\d)/
      
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
    report_type == TYPE_START_STOP
  end
  
  def timeString
    case report_type
      when TYPE_START_STOP then formatted_start_time + ' - ' + formatted_end_time + 
                          ' (' + ((hours*100).round / 100.0).to_s + ' h)'
      when TYPE_HOURS_DAY then hours.to_s + ' h'
      when TYPE_HOURS_WEEK then hours.to_s + ' h this week'
      when TYPE_HOURS_MONTH then hours.to_s + ' h this month'
    end
  end
  
  def validate
    if times?
      errors.add(:from_start_time, 'is invalid') if ! from_start_time
      errors.add(:to_end_time, 'is invalid') if ! to_end_time
      errors.add(:to_end_time, 'should be after start time') if from_start_time && 
          to_end_time && to_end_time <= from_start_time
    else
      errors.add(:hours, 'should be positive') if hours <= 0
    end
  end
  
  def store_hours
    if times? && from_start_time && to_end_time
      self.hours = (to_end_time - from_start_time) / 3600.0
    end
  end
  
private

  def formatted_time(time)
    time ||= Time.now
    time.strftime("%H:%M")
  end

  def string_to_time(value)
    if value.kind_of?(String) && ! (value =~ H_M)
      value = value.to_f
      value = value.to_i.to_s + ':' + ((value - value.to_i) * 60).to_i.to_s
    end
    value
  end
  
end
