# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base
  
  has_many :projectmemberships, :dependent => true
  has_many :employees, :through => :projectmemberships
  belongs_to :client
  has_many :worktimes
  
  validates_presence_of :name, :description
  validates_uniqueness_of :name
  
  def sumProjectTime(employee_id)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ?", id, employee_id])
  end
end
