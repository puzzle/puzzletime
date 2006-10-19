# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base
  include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods
  has_many :projectmemberships, :dependent => true
  has_many :employees, :through => :projectmemberships
  belongs_to :client
  has_many :worktimes
  
  validates_presence_of :name, :description
  validates_uniqueness_of :name
  
  def sumProjectTime(employee_id)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ?", id, employee_id])
  end
  
  def sumProjectAllTime
    Worktime.sum(:hours, :conditions => ["project_id = ?",id])
  end
  
  def sumProjectCurrentWeek(employee_id)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, "#{Time.now.year}-#{Time.now.month}-#{Time.now.day-7}", "#{Time.now.year}-#{Time.now.month}-#{Time.now.day}"])
  end
  
  def sumProjectCurrentMonth(employee_id)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, "#{Time.now.year}-#{Time.now.month}-01", "#{Time.now.year}-#{Time.now.month}-#{days_in_month(Time.now.month)}"])
  end
  
  def sumProjectCurrentYear(employee_id)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, "#{Time.now.year}-01-01", "#{Time.now.year}-12-#{days_in_month(Time.now.month)}"])
  end
  
  def sumProjectPeriod(employee_id, startdate, enddate)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, startdate, enddate])
  end
end
