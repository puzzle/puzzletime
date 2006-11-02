# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

require "digest/sha1"

class Employee < ActiveRecord::Base
  
  # All dependencies between the models are listed below.
  has_many :employments 
  has_many :projectmemberships, :dependent => true
  has_many :projects, :through => :projectmemberships
  has_many :worktimes, :dependent => true
  has_many :absences, :through => :worktimes
  
  # Attribute reader and writer.
  attr_accessor :pwd 
  
  # Validation helpers.
  validates_presence_of :firstname, :lastname, :shortname, :email, :phone
  validates_presence_of :pwd, :on => :create
  validates_uniqueness_of :shortname 
  
  # Hashes password before storing it.
  def before_create
    self.passwd = Employee.encode(self.pwd)
  end
  
  # After created password, instance pwd should be nil
  def after_create
    @pwd = nil
  end
  
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
  
  # Saves new password in DB.
  def updatepwd(pwd)
    hashed_pwd = Employee.encode(pwd)
    update_attributes(:passwd => hashed_pwd)
  end
  
  # Sum total worked time
  def sumWorktime(start_date, end_date)
   if self.worktimes.sum(:hours, :joins => "LEFT JOIN absences AS a ON worktimes.absence_id = a.id", :conditions => ["(worktimes.absence_id IS NULL OR a.payed) AND work_date BETWEEN ? AND ?",start_date, end_date]) == nil
     return 0
   else
     self.worktimes.sum(:hours, :joins => "LEFT JOIN absences AS a ON worktimes.absence_id = a.id", :conditions => ["(worktimes.absence_id IS NULL OR a.payed) AND work_date BETWEEN ? AND ?",start_date, end_date])
   end
  end
  
  # Calculates remaining holidays
  def remainingHolidays
    ((totalHolidays-usedHolidays)/8).to_f
  end
  
  # Calculates used holidays
  def usedHolidays
    if self.worktimes.sum(:hours, :conditions => ["absence_id = ?", Holiday::VACATION_ID]) == nil
      return 0
    else
      self.worktimes.sum(:hours, :conditions => ["absence_id = ?", Holiday::VACATION_ID])
    end
  end
  
  # Calculates total holidays
  def totalHolidays
    first_employment = self.employments.find(:first)
    sumTotal = 0
    if first_employment == nil
      sumTotal 
    else
      first_employment.start_date.year.step(Date.today.year, 1){|year|
      sumTotal += Masterdata.instance.vacations_year
      }
      sumTotal
    end
  end

  # Sum total overtime
  def totalOvertime
    first_employment = self.employments.find(:first)
    if first_employment == nil
      return 0
    else
      sumWorktime(first_employment.start_date, Date.today)-musttime(first_employment.start_date, Date.today)
    end
  end
  
  # Sum musttime
  def musttime(start_date, end_date)
    employments = self.employments.find(:all, :conditions =>["start_date <= ? OR end_date IS NULL OR end_date >= ? OR start_date <= ? OR end_date >= ? ",end_date ,start_date, start_date, end_date])
    currentEmployment = 0
    sum = 0
    start_date.step(end_date,1) {|date|
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
  
  # Hash function for pwd.
  private
  def self.encode(pwd)
    Digest::SHA1.hexdigest(pwd) 
  end
end
