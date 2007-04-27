# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

require "digest/sha1"
require "net/ldap"

class Employee < ActiveRecord::Base
  
  include Evaluatable
  extend Manageable
  
  # All dependencies between the models are listed below.
  has_many :employments, :order => 'start_date DESC', :dependent => :destroy
  has_many :projectmemberships, :dependent => :destroy
  has_many :projects, 
           :include => :client,
           :through => :projectmemberships, 
           :order => "clients.name, projects.name"
  has_many :managed_projects, 
           :class_name => 'Project', 
           :through => :projectmemberships, 
           :include => :client,
           :order => "clients.name, projects.name", 
           :conditions => "projectmemberships.projectmanagement IS TRUE"
  has_many :absences, :finder_sql => 
              'SELECT DISTINCT(a.*) FROM absences a, worktimes t WHERE ' +
              't.employee_id = #{id} AND t.absence_id = a.id ' +
              'ORDER BY a.name'         
  has_many :managed_employees, 
           :class_name => 'Employee', 
           :finder_sql =>
              'SELECT DISTINCT(e.*) ' + 
              'FROM employees e, projectmemberships m, projectmemberships n WHERE ' +
              'm.employee_id = #{id} AND m.projectmanagement AND ' +
              'm.project_id = n.project_id AND n.employee_id = e.id ' +
              'ORDER BY e.lastname, e.firstname'
  has_many :worktimes
  has_many :attendancetimes
  has_many :overtime_vacations, :order => 'transfer_date DESC', :dependent => :destroy        
  has_one  :auto_start_time, 
           :class_name => 'Attendancetime',
           :conditions => "report_type = '#{AutoStartType::INSTANCE.key}'"
  
  # Validation helpers.
  validates_presence_of :firstname, :message => "Der Vorname muss angegeben werden"
  validates_presence_of :lastname, :message => "Der Nachname muss angegeben werden"
  validates_presence_of :shortname, :message => "Das K&uuml;rzel muss angegeben werden"
  validates_uniqueness_of :shortname, :message => "Dieses K&uuml;rzel wird bereits verwendet"
  
  before_destroy :protect_worktimes  
 
  # Tries to login a user with the passed data.
  # Returns the logged-in Employee or nil if the login failed.
  def self.login(username, pwd)    
    user = find_by_shortname_and_passwd(username.upcase, encode(pwd))
    user = ldapLogin(username, pwd) if user.nil?   
    user
  end
  
  # Performs a login over LDAP with the passed data.
  # Returns the logged-in Employee or nil if the login failed.
  def self.ldapLogin(username, pwd)
    if ! username.strip.empty? && 
       ldapConnection.bind_as(:base => LDAP_DN, 
                              :filter => "uid=#{username}", 
                              :password => pwd)
      return find_by_ldapname(username)
    end  
    nil
  end
  
  # Returns a Array of LDAP user information
  def self.ldapUsers       
     ldapConnection.search(:base => LDAP_DN,  
                           :attributes => ['uid', 'sn', 'givenname', 'mail'] )
  end
  
  ##### interface methods for Manageable #####  
    
  def self.labels
    ['Der', 'Mitarbeiter', 'Mitarbeiter']
  end  
  
  def self.orderBy 
    'lastname, firstname'
  end
  
  def self.columnType(col)
    case col 
      when :current_percent : :integer
      else super col
      end
  end  
      
  def self.puzzlebaseMap
    Puzzlebase::Employee
  end  
      
  ##### interface methods for Evaluatable #####    
  
  def label
    lastname + " " + firstname
  end  
  
  # Redirects the messages :sumWorktime, :countWorktimes, :findWorktimes
  # to the Worktime Class.
  def self.method_missing(symbol, *args)
    case symbol
      when :sumWorktime, :countWorktimes, :findWorktimes : Worktime.send(symbol, *args) 
      else super
      end
  end
  
  # Sums the attendance times of this Employee.
  def sumAttendance(period = nil, options = {})
    self.class.sumAttendanceFor attendancetimes, period, options
  end
  
  # Sums all attendance times in the system.
  def self.sumAttendance(period = nil, options = {})
    sumAttendanceFor Attendancetime, period, options
  end
  
  ##### helper methods #####
    
  # Whether this Employee is a project manager  
  def projectManager?
    managed_projects.size > 0
  end  
  
  # Accessor for the initial vacation days. Default is 0.
  def initial_vacation_days
    super || 0    
  end
  
  def before_create
    self.passwd = ""    # disable password login  
  end
  
  def checkPasswd(pwd)
    self.passwd == Employee.encode(pwd)
  end
  
  def setPasswd(pwd)
    update_attributes(:passwd => Employee.encode(pwd))
  end

  # Sums the worktimes of all managed projects.
  def sumManagedProjectsWorktime(period)
    sql = "SELECT sum(hours) AS sum " +
           "FROM ((employees E LEFT JOIN projectmemberships PM ON E.id = PM.employee_id) " +
	       " LEFT JOIN projects P ON PM.project_id = P.id)" +
           " LEFT JOIN worktimes T ON P.id = T.project_id " +
           "WHERE E.id = #{self.id} AND PM.projectmanagement"    
    sql += " AND T.work_date BETWEEN #{period.startDate} AND #{period.endDate}" if period
    self.class.connection.select_value(sql).to_f
  end
   
  # Returns the date the passed project was completed last. 
  def lastCompleted(project)
    projectmemberships.find_by_project_id(project.id).last_completed
  end
  
  #########  vacation and overtime information ############
  
  # Returns the unused days of vacation remaining until the end of the current year.
  def currentRemainingVacations
     remainingVacations(Date.new(Date.today.year, 12, 31))
  end
  
  # Returns the unused days of vacation remaining until the given date.
  def remainingVacations(date)
    period = employmentPeriodTo(date)
    initial_vacation_days + totalVacations(period) + 
      overtimeVacationHours(date) / 8.0 - usedVacations(period)
  end
  
  # Returns the overall amount of granted vacation days for the given period.
  def totalVacations(period)
    employmentsDuring(period).sum(&:vacations)
  end
  
  # Returns the used vacation days for the given period
  def usedVacations(period)
    return 0 if period.nil?
    worktimes.sum(:hours, :conditions => ["absence_id = ? AND (work_date BETWEEN ? AND ?)", 
      VACATION_ID, period.startDate, period.endDate]).to_f / 8.0
  end
  
  # Returns the overall overtime hours until the given date.
  # Default is yesterday.   
  def currentOvertime(date = Date.today - 1)
    overtime(employmentPeriodTo(date)) - overtimeVacationHours
  end
  
  # Returns the overtime hours worked in the given period.
  def overtime(period)
    payedWorktime(period) - musttime(period)
  end
  
  # Returns the hours this employee has to work in the given period.
  def musttime(period)
    employmentsDuring(period).sum(&:musttime)
  end  
  
  # Returns the hours this employee worked plus the payed absences for the given period.
  def payedWorktime(period)
    condArray = ["((project_id IS NULL AND absence_id IS NULL) OR absences.payed)"]
    if period
      condArray[0] += " AND (work_date BETWEEN ? AND ?)"    
      condArray.push period.startDate
      condArray.push period.endDate
    end      
    worktimes.sum(:hours, 
                  :joins => 'LEFT JOIN absences ON absences.id = absence_id',
                  :conditions => condArray).to_f
  end
  
  # Return the overtime hours that were transformed into vacations up to the given date.
  def overtimeVacationHours(date = nil)    
    overtime_vacations.sum(:hours,
                           :conditions => date ? ['transfer_date <= ?', date] : nil).to_f
  end
  
  ######### employment information ######################
  
  # Returns the current employement percent value.
  # Returns nil if no current employement is present.
  def current_percent
    empl = current_employment
    empl.percent if empl
  end
  
  # Returns the current employement, nil if none is present.
  def current_employment
    employment_at(Date.today) 
  end
  
  # Returns the employement at the given date, nil if none is present.
  def employment_at(date)
    employments.find( :first, :conditions => 
      ['start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date] ) 
  end
  
  # Returns an Array of all employements during the given period, 
  # an empty Array if no employments exist.
  def employmentsDuring(period)
    return [] if period.nil?
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
    selectedEmployments    
  end
    
  # Returns the Period from the first employement date until the given period.
  # Returns nil if no employments exist until this date.  
  def employmentPeriodTo(date)
    first_employment = self.employments.find(:first, :order => 'start_date ASC')
    return nil if first_employment == nil || first_employment.start_date > date
    Period.new(first_employment.start_date, date)
  end
  
private

  def self.encode(pwd)
    Digest::SHA1.hexdigest(pwd) 
  end
  
  def self.ldapConnection
    Net::LDAP.new :host => LDAP_HOST, 
                  :port => LDAP_PORT, 
                  :encryption => :simple_tls  
  end
  
  def self.sumAttendanceFor(receiver, period = nil, options = {})
    options[:conditions] = [ "work_date BETWEEN ? AND ?", period.startDate, period.endDate ] if period
    receiver.sum(:hours, options).to_f
  end
  
end
