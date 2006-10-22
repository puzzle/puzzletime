# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Project < ActiveRecord::Base
  
  include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods

  # All dependencies between the models are listed below
  has_many :projectmemberships, :dependent => true
  has_many :employees, :through => :projectmemberships
  belongs_to :client
  has_many :worktimes
  
  # Validation helpers  
  validates_presence_of :name, :description
  validates_uniqueness_of :name
  
  # Gets the sum of project selected from employee
  def sumProjectTime(employee_id)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ?", id, employee_id])
  end
  
  # Gets the sum of project hours of current week from employee
  def sumProjectCurrentWeek(employee_id)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, "#{Time.now.year}-#{Time.now.month}-#{Time.now.day-7}", "#{Time.now.year}-#{Time.now.month}-#{Time.now.day}"])
  end
  
  # Gets the sum of project hours of current month from employee
  def sumProjectCurrentMonth(employee_id)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, "#{Time.now.year}-#{Time.now.month}-01", "#{Time.now.year}-#{Time.now.month}-#{days_in_month(Time.now.month)}"])
  end
  
  # Gets the sum of project hours of current year from employee
  def sumProjectCurrentYear(employee_id)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, "#{Time.now.year}-01-01", "#{Time.now.year}-12-31"])
  end
  
  # Gets the sum of project hours of selected period from employee
  def sumProjectPeriod(employee_id, startdate, enddate)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, startdate, enddate])
  end
  
  # Gets the sum of project hours of current week
  def sumProjectWeek
    Worktime.sum(:hours, :conditions => ["project_id = ? AND work_date BETWEEN ? AND ?", id, "#{Time.now.year}-#{Time.now.month}-#{Time.now.day-7}", "#{Time.now.year}-#{Time.now.month}-#{Time.now.day}"])
  end
  
  # Gets the sum of project hours of current month
  def sumProjectMonth
    Worktime.sum(:hours, :conditions => ["project_id = ? AND  work_date BETWEEN ? AND ?", id, "#{Time.now.year}-#{Time.now.month}-01", "#{Time.now.year}-#{Time.now.month}-#{days_in_month(Time.now.month)}"])
  end 
  
  # Gets the sum of project hours of current year
  def sumProjectYear
    Worktime.sum(:hours, :conditions => ["project_id = ? AND work_date BETWEEN ? AND ?", id, "#{Time.now.year}-01-01", "#{Time.now.year}-12-31"])
  end
  # Gets the total sum of project hours 
  def sumProjectTotal
    Worktime.sum(:hours, :conditions => ["project_id = ?", id])
  end
  
  # Gets all projects with times of clients
  def sumProjectPeriodForClient(startdate, enddate)
    Worktime.sum(:hours, :conditions => ["project_id = ? AND work_date BETWEEN ? AND ?", id, startdate, enddate])
  end
end
