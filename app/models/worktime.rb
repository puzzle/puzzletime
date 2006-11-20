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

  def validate
    if hours.to_f <= 0
      errors.add(hours, "hours must be positive")
    end
  end  
    
  def account
    project != nil ? project : absence
  end
end
