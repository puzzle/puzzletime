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
  
  # Calculates remaining holidays
  def remainingHolidays
    ((totalHolidays - usedHolidays) / 8).to_f
  end
  
  # Calculates used holidays
  def usedHolidays
    self.worktimes.sum(:hours, :conditions => ["absence_id = ?", Holiday::VACATION_ID]).to_f
  end
  
  # Calculates total holidays
  def totalHolidays
    first_employment = self.employments.find(:first)
    sumTotal = 0
    if first_employment != nil
      first_employment.start_date.year.step(Date.today.year, 1) {|year|
        sumTotal += Masterdata.instance.vacations_year
      }      
    end
    sumTotal
  end

  # Sum total overtime
  def totalOvertime
    first_employment = self.employments.find(:first)
    return 0 if first_employment == nil
    period = Period.new(first_employment.start_date, Date.today)
    sumWorktime(period) - musttime(period)
  end
  
  # Sum musttime
  def musttime(period)
    employments = self.employments.find(:all, :conditions =>["start_date <= ? OR end_date IS NULL OR end_date >= ? OR start_date <= ? OR end_date >= ? ", period.endDate, period.startDate, period.startDate, period.endDate])
    currentEmployment = 0
    sum = 0
    period.step {|date|
      hours = Holiday.mustTime(date)
      if employments[currentEmployment].end_date != nil
        if employments[currentEmployment].end_date < date && currentEmployment < employments.length-1
          currentEmployment += 1
        end 
        # testing needed as currentEmployment could be before or after date, 
        # if there is no present employment for date.
        if date.between?(employments[currentEmployment].start_date, employments[currentEmployment].end_date)
            sum += hours * employments[currentEmployment].percent / 100
        end
      else
      sum += hours * employments[currentEmployment].percent / 100
      end      
    }
    sum
  end
  
private
  
  # Hash function for pwd.  
  def self.encode(pwd)
    Digest::SHA1.hexdigest(pwd) 
  end
end
