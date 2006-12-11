# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Client < ActiveRecord::Base

  include Category
  include Division

  # All dependencies between the models are listed below.
  has_many :projects, :order => "name"
  has_many :worktimes, :through => :projects
  
  # Validation helpers.
  validates_presence_of :name
  validates_uniqueness_of :name
   
  def self.list 
    find(:all, :order => "name")  
  end
  
  def subdivisionRef
    0
  end
  
  def detailFor(time)
    time.employee.shortname
  end
  
  def worktimesBy(period, absences = nil)
    worktimes.find(:all, 
                   :conditions => conditionsFor(period, {:client_id => id}, absences), 
                   :order => "work_date ASC, from_start_time ASC")
  end  
end
