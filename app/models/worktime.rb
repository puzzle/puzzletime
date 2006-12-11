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
  validates_inclusion_of :hours, :in => 0..750, :message => "should be positive"
      
  def account
    project != nil ? project : absence
  end
  
  def absence?
    absence_id != nil
  end
end
