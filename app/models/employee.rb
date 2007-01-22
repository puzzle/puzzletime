# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

require "digest/sha1"

class Employee < ActiveRecord::Base
  
  include Evaluatable
  
  # All dependencies between the models are listed below.
  has_many :employments, :order => 'start_date', :dependent => true
  has_many :projectmemberships, :dependent => true
  has_many :projects, 
           :through => :projectmemberships, 
           :order => "client_id, name"
  has_many :managed_projects, 
           :class_name => 'Project', 
           :through => :projectmemberships, 
           :order => "client_id, name", 
           :conditions => "projectmemberships.projectmanagement IS TRUE"
  has_many :worktimes, :dependent => true
  has_many :absences, :finder_sql => 
              'SELECT DISTINCT(a.*) FROM absences a, worktimes t WHERE ' +
              't.employee_id = #{id} AND t.absence_id = a.id ' +
              'ORDER BY a.name'

  # Attribute reader and writer.
  attr_accessor :pwd 
  
  # Validation helpers.
  validates_presence_of :firstname, :lastname, :shortname
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
    
  def self.label
    'Mitarbeiter'
  end  
  
  def label
    lastname + " " + firstname
  end
  
  def partnerId
    :project_id
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
  
  def currentRemainingVacations
    initial_vacation_days + remainingVacations(employmentPeriodTo(endOfYear))
  end
  
  # Calculates remaining Vacations
  def remainingVacations(period)
    totalVacations(period) - usedVacations(period)
  end
  
  # Calculates used holidays
  def usedVacations(period)
    return 0 if period == nil
    self.worktimes.sum(:hours, :conditions => ["absence_id = ? AND (work_date BETWEEN ? AND ?)", 
      VACATION_ID, period.startDate, period.endDate]).to_f / 8
  end
    
  # Calculates total holidays
  def totalVacations(period)
    days = 0
    employmentsDuring(period).each do |e|
      days += e.vacations
    end
    return days  
  end

  def currentOvertime(date = Date.today - 1)
    overtime(employmentPeriodTo(date))
  end
  
  # Sum total overtime
  def overtime(period)
    payedWorktime(period) - musttime(period)
  end
  
  def payedWorktime(period)
    condArray = ["(absence_id IS NULL OR absences.payed)"]
    if period
      condArray[0] += " AND (work_date BETWEEN ? AND ?)"    
      condArray.push period.startDate
      condArray.push period.endDate
    end      
    worktimes.sum(:hours, 
                  :joins => 'LEFT JOIN absences ON absences.id = absence_id',
                  :conditions => condArray).to_f
  end
  
  def musttime(period)
    musttime = 0
    employmentsDuring(period).each do |e|
      musttime += e.musttime
    end
    return musttime      
  end
  
  def current_employment
    employments.find(:first, 
          :conditions => ['start_date <= ? AND (end_date IS NULL OR end_date >= ?)', 
            Date.today, Date.today])  
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
