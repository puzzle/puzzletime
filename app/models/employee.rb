# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

require "digest/sha1"

class Employee < ActiveRecord::Base

  has_many :employments 
  has_many :projectmemberships, :dependent => true
  has_many :projects, :through => :projectmemberships
  has_many :worktimes
  
  attr_accessor :pwd 
  
  
  validates_presence_of :firstname, :lastname, :shortname, :email, :phone, :on => :update
  validates_presence_of :pwd, :on => :create
  validates_uniqueness_of :shortname 
  
  def before_create
    self.passwd = Employee.encode(self.pwd)
  end
  
  def after_create
    @pwd = nil
  end
  
  def self.login(shortname, pwd)
    passwd = encode(pwd)
    find(:first,
         :conditions =>["shortname = ? and passwd = ?",
                         shortname, passwd])
  end
  
  def self.checkpwd(id, pwd)
    passwd = encode(pwd)
    nil != find(:first,
         :conditions =>["id = ? and passwd = ?",
                         id, passwd])
  end
  
  def sumVacation
    
    tmp_lastYearStart = "#{Time.now.year-1}-1-1"
    tmp_lastYearEnd = "#{Time.now.year-1}-12-31"
    tmp_actualYearStart = "#{Time.now.year}-1-1"
    tmp_actualYearEnd = "#{Time.now.year}-12-31"
    
    lastYear_used_holidays = Worktime.sum(:hours, :conditions => ["absence_id = ? AND employee_id = ? AND work_date < ? AND work_date > ?",Absence::VACATION_ID, id, tmp_lastYearEnd, tmp_lastYearStart])
    
    if lastYear_used_holidays == nil
      lastYear_not_used_holidays = (Masterdata.sum(:vacations_year)/8).to_f
    else
      lastYear_not_used_holidays = (Masterdata.sum(:vacations_year)-lastYear_used_holidays)/8
    end
    
    actual_used_holidays = Worktime.sum(:hours, :conditions => ["absence_id = ? AND employee_id = ? AND work_date < ? AND work_date > ?",Absence::VACATION_ID, id, tmp_actualYearEnd, tmp_actualYearStart])
    
    
    if actual_used_holidays == nil
      actual_not_used_holidays = (Masterdata.sum(:vacations_year)/8).to_f + lastYear_not_used_holidays
    else
      actual_not_used_holidays = (Masterdata.sum(:vacations_year)-actual_used_holidays)/8 + lastYear_not_used_holidays
    end
  end
  
  def updatepwd(pwd)
    hashed_pwd = Employee.encode(pwd)
    update_attributes(:passwd => hashed_pwd)
  end
  
  private
  def self.encode(pwd)
    Digest::SHA1.hexdigest(pwd) 
  end
end
