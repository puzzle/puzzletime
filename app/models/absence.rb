# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Absence < ActiveRecord::Base

  include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods
  
  # All dependencies between the models are listed below
  has_many :worktimes, :dependent => true
  has_many :employees, :through => :worktimes, :order => "lastname"

  # Validation helpers
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def self.list(id = nil)
    if id != nil
      find(id).to_a
    else  
      find(:all, :order => "name")  
    end  
  end
  
  def self.division
    :absences
  end  
  
  def label
    name
  end  
  
  def subdivisionRef
    id
  end
  
  def detailFor(time)
    ""
  end
  
  def worktimesBy(period = nil, employeeId = 0)
    worktimes.find(:all, :conditions => Worktime.conditionsFor(period, :employee_id => employeeId), :order => "work_date ASC")
  end  
  
  def sumWorktime(period = nil, employeeId = 0)
    worktimes.sum(:hours, :conditions => Worktime.conditionsFor(period, :employee_id => employeeId)).to_f
  end

end
