# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Absence < ActiveRecord::Base

  include ActiveSupport::CoreExtensions::Time::Calculations::ClassMethods
  
  # All dependencies between the models are listed below
  has_many :worktimes, :dependent => true
  has_many :employees, :through => :worktimes

  # Validation helpers
  validates_presence_of :name
  validates_uniqueness_of :name
  
  # Gets the sum of absence hours of current week from DB
  def sumAbsenceCurrentWeek(employee_id)
    Worktime.sum(:hours, :conditions => ["absence_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, "#{Time.now.year}-#{Time.now.month}-#{Time.now.day-7}", "#{Time.now.year}-#{Time.now.month}-#{Time.now.day}"])
  end
  
  # Gets the sum of absence hours of current month from DB
  def sumAbsenceCurrentMonth(employee_id)
    Worktime.sum(:hours, :conditions => ["absence_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, "#{Time.now.year}-#{Time.now.month}-01", "#{Time.now.year}-#{Time.now.month}-#{days_in_month(Time.now.month)}"])
  end
  
  # Gets the sum of absence hours of current year from DB
  def sumAbsenceCurrentYear(employee_id)
    Worktime.sum(:hours, :conditions => ["absence_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, "#{Time.now.year}-01-01", "#{Time.now.year}-12-#{days_in_month(Time.now.month)}"])
  end
  
  # Gets the sum of absence hours of selected period from DB
  def sumAbsencePeriod(employee_id, startdate, enddate)
    Worktime.sum(:hours, :conditions => ["absence_id = ? AND employee_id = ? AND work_date BETWEEN ? AND ?", id, employee_id, startdate, enddate])
  end
end
