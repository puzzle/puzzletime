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
  
  
  def sumWorktime(start_date, end_date)
   self.worktimes.sum(:hours, :joins => "LEFT JOIN absences AS a ON worktimes.absence_id = a.id", :conditions => ["(worktimes.absence_id IS NULL OR a.payed) AND work_date BETWEEN ? AND ?",start_date, end_date])
  end

  def totalOvertime(employee)
    first_employment = self.employments.find(:first)
    puts "Mitarbeitername: #{employee.lastname}"
    puts "First Employment: #{first_employment.start_date}"
    self.overtime(first_employment.start_date, Date.today)
  end
  
  def overtime(start_date, end_date)
     sumWorktime(start_date, end_date) - musttime(start_date, end_date)
  end
  
  def musttime(start_date, end_date)
    employments = self.employments.find(:all, :conditions =>["start_date <= ? OR end_date IS NULL OR end_date >= ? OR start_date <= ? OR end_date <= ? ",end_date ,start_date, start_date, end_date])
    currentEmployment = 0
    sum = 0
    
    puts "Das Startdatum: #{start_date}"
    puts "Das Enddatum: #{end_date}"
    start_date.step(end_date,1) {|date|
      hours = Holiday.mustTime(date)
      puts "Aktuelles Datum der Schlaufe: #{date}",date.strftime("%A")
      puts "Hour nach Holiday must Time: #{hours}"
      puts "SUM nach Holiday must Time: #{sum}"
      puts "Aktueller Index: #{currentEmployment}"
      if employments[currentEmployment].end_date != nil
        puts "Current employment enddate not nil"
        if employments[currentEmployment].end_date < date && currentEmployment < employments.length-1
          currentEmployment += 1
          puts "Aktueller Index in der if schlaufe: #{currentEmployment}"
        end 
        # testing needed as currentEmployment could be before or after date, 
        # if there is no present employment for date.
        if date.between?(employments[currentEmployment].start_date, employments[currentEmployment].end_date)
            sum += hours * employments[currentEmployment].percent / 100
        end
        puts "SUM nach date between Time: #{sum}"
      else
      sum += hours * employments[currentEmployment].percent / 100
      puts "SUM nach else Time: #{sum}"
      end      
    puts "--------------------------------------------"
    }
    sum
  end
  
  # Hash function for pwd.
  private
  def self.encode(pwd)
    Digest::SHA1.hexdigest(pwd) 
  end
end
