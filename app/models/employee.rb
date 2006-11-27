# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

require "digest/sha1"

class Employee < ActiveRecord::Base
  
  include Category
  include Division
  
  # All dependencies between the models are listed below.
  has_many :employments, :order => 'start_date'
  has_many :projectmemberships, :dependent => true
  has_many :projects, :through => :projectmemberships, :order => "name"
  has_many :managed_projects, :class_name => 'Project', :through => :projectmemberships, :order => "name"
  has_many :worktimes, :dependent => true
  has_many :absences, :through => :worktimes

  
  # Attribute reader and writer.
  attr_accessor :pwd 
  
  # Validation helpers.
  validates_presence_of :firstname, :lastname, :shortname, :email, :phone
  validates_presence_of :pwd, :on => :create
  validates_uniqueness_of :shortname 
  
  # Hashes and compares the pwd.
  def self.login(shortname, pwd)
    passwd = encode(pwd)
    find(:first,
         :conditions =>["shortname = ? and passwd = ?",
                         shortname, passwd])
  end
  
  # Checks password before updating.
  def self.checkpwd(id, pwd)
    passwd = encode(pwd)
    nil != find(:first,
         :conditions =>["id = ? and passwd = ?",
                         id, passwd])
  end
  
  def self.list 
    find(:all, :order => "lastname")  
  end
  
  def label
    lastname + " " + firstname
  end
  
  def worktimesBy(period, projectId)
    worktimes.find(:all, :conditions => conditionsFor(period, :project_id => projectId), :order => "work_date ASC")
  end  
  
  def sumWorktime(period = nil, projectId = 0)
    worktimes.sum(:hours, :conditions => conditionsFor(period, :project_id => projectId)).to_f
  end
    
  def projectManager?
    managed_projects.size > 0
  end  
  
  # Hashes password before storing it.
  def before_create
    self.passwd = Employee.encode(self.pwd)
  end
  
  # After created password, instance pwd should be nil
  def after_create
    @pwd = nil
  end
   
  # Saves new password in DB.
  def updatepwd(pwd)
    hashed_pwd = Employee.encode(pwd)
    update_attributes(:passwd => hashed_pwd)
  end
  
  def currentRemainingHolidays
    remainingHolidays(employmentPeriodTo(endOfYear))
  end
  
  # Calculates remaining holidays
  def remainingHolidays(period)
    totalHolidays(period) - usedHolidays(period)
  end
  
  # Calculates used holidays
  def usedHolidays(period)
    return 0 if period == nil
    self.worktimes.sum(:hours, :conditions => ["absence_id = ? AND (work_date BETWEEN ? AND ?)", 
      Holiday::VACATION_ID, period.startDate, period.endDate]).to_f / 8
  end
    
  # Calculates total holidays
  def totalHolidays(period)
    holidays = 0
    employmentsDuring(period).each {|e|
      holidays += e.holidays
    } 
    return holidays  
  end

  def currentOvertime
    overtime(employmentPeriodTo(Date.today))
  end

  # Sum total overtime
  def overtime(period)
    sumWorktime(period) - musttime(period)
  end
  
  def musttime(period)
    musttime = 0
    employmentsDuring(period).each {|e|
      musttime += e.musttime
    }
    return musttime      
  end
  
  def employmentsDuring(period)
    return [] if period == nil
    selectedEmployments = employments.find(:all, 
      :conditions => ["(end_date IS NULL OR end_date >= ?) AND start_date <= ?", 
      period.startDate, period.endDate],
      :order => 'start_date')
    if ! selectedEmployments.empty?
      selectedEmployments.first.start_date = period.startDate
      if selectedEmployments.last.end_date == nil ||
         selectedEmployments.last.end_date > period.endDate then
        selectedEmployments.last.end_date = period.endDate
      end  
    end
    return selectedEmployments    
  end
    
  def employmentPeriodTo(date)
    first_employment = self.employments.find(:first)
    return nil if first_employment == nil || first_employment.start_date > date
    return Period.new(first_employment.start_date, date)
  end
  
private

  def endOfYear
    Date.new(Date.today.year, 12, 31)
  end
    
  # Hash function for pwd.  
  def self.encode(pwd)
    Digest::SHA1.hexdigest(pwd) 
  end
end
