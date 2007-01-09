# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Worktime < ActiveRecord::Base
  
  # All dependencies between the models are listed below.
  belongs_to :absence 
  belongs_to :employee
  belongs_to :project
  
  #Accessor needed for all select*.rhtml
  attr_accessor :start
  attr_accessor :end
    
  TYPE_START_STOP = 'start_stop_day'
  TYPE_HOURS_DAY = 'absolute_day'
  TYPE_HOURS_WEEK = 'week'
  TYPE_HOURS_MONTH = 'month'
  
  validates_presence_of :work_date, :message => "is invalid"
  validates_inclusion_of :hours, :in => 0.0001..750, :message => "should be positive"
      
  def account
    project != nil ? project : absence
  end
  
  def absence?
    absence_id != nil
  end
  
  def times?
    report_type == TYPE_START_STOP
  end
  
  def timeString
    case report_type
    when TYPE_START_STOP: from_start_time.strftime("%H:%M") + ' - ' + 
                          to_end_time.strftime("%H:%M") + 
                          ' (' + ((hours*100).round / 100.0).to_s + ' h)'
    when TYPE_HOURS_DAY: hours.to_s + ' h'
    when TYPE_HOURS_WEEK: hours.to_s + ' h this week'
    when TYPE_HOURS_MONTH: hours.to_s + ' h this month'
    end
  end
  
end
