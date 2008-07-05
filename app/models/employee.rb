require "date"
require "digest"
require "digest/sha1"
require "net/ldap"

class Employee < ActiveRecord::Base
  
  include Evaluatable
  include ReportType::Accessors
  extend Conditioner
  extend Manageable
  
  # All dependencies between the models are listed below.
  has_many :employments, :order => 'start_date DESC', :dependent => :destroy
  has_many :projectmemberships, 
           :dependent => :destroy,
           :include => [ { :project => :client } ],
           :order => 'clients.shortname, projects.name'
  has_many :projects, 
           :include => :client,
           :through => :projectmemberships, 
           :conditions => 'projectmemberships.active',
           :order => "clients.shortname, projects.name"
  has_many :clients, :through => :projects, :order => 'shortname'    
  has_many :managed_projects, 
           :class_name => 'Project', 
           :through => :projectmemberships, 
           :include => :client,
           :order => "clients.name, projects.name", 
           :conditions => "projectmemberships.projectmanagement AND projectmemberships.active"
  has_many :absences, 
           :through => :worktimes,
           :uniq => true,
           :order => 'name'     
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
  validates_uniqueness_of :ldapname, :message => "Dieses LDAP Name wird bereits verwendet"
  
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
  
  def self.employed_ones(period)
     find(:all, :select => 'distinct (employees.*)',
                :joins => 'left outer join employments em on em.employee_id = employees.id', 
                :conditions => ['(em.end_date IS null or em.end_date >= ?) AND em.start_date <= ?', 
                                period.startDate, period.endDate ],
                :order => orderBy)
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
      when :default_report_type : :report_type
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
    self.projectmemberships.build(:project_id => DEFAULT_PROJECT_ID)
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
          "FROM (((employees E LEFT JOIN projectmemberships PM ON E.id = PM.employee_id) " +
	        " LEFT JOIN projects P ON PM.project_id = P.id)" +
          " LEFT JOIN projects C ON P.id = ANY (C.path_ids))" +
          " LEFT JOIN worktimes T ON C.id = T.project_id " +
          "WHERE E.id = #{self.id} AND PM.projectmanagement"    
    sql += " AND T.work_date BETWEEN '#{period.startDate}' AND '#{period.endDate}'" if period
    self.class.connection.select_value(sql).to_f
  end
  
  def alltime_projects
    Project.find_by_sql ["SELECT DISTINCT c.shortname, pa.* FROM  worktimes w " + 
                "LEFT JOIN projects pw ON w.project_id = pw.id " + 
                "LEFT JOIN projects pa ON pw.path_ids[1] = pa.id " +
                "LEFT JOIN clients c ON pa.client_id = c.id " +
                "WHERE w.employee_id = ? AND pa.id IS NOT NULL " + 
                "ORDER BY c.shortname, pa.name", self.id]
  end
   
  # Returns the date the passed project was completed last. 
  def lastCompleted(project)
    path = project.path_ids.clone
    membership = nil
    while membership.nil? && !path.empty?
      membership = projectmemberships.find(:first, :conditions => ['project_id = ?', path.pop])
    end
    membership.last_completed if membership
  end
  
  def leaf_projects(list = nil)
    list ||= projects
    list.collect{|p| p.leaves }.flatten.uniq
  end
  
  def alltime_leaf_projects
    leaf_projects((alltime_projects + projects).sort)
  end
  
  def statistics
    @statistics ||= EmployeeStatistics.new(self)
  end
  
  def user_periods=(periods)
    write_array_attribute(:user_periods, periods)
  end

  def user_periods
    read_array_attribute(:user_periods)
  end

  def eval_periods=(periods)
    write_array_attribute(:eval_periods, periods)
  end

  def eval_periods
    read_array_attribute(:eval_periods)
  end
  
  ######### employment information ######################
  
  # Returns the current employement percent value.
  # Returns nil if no current employement is present.
  def current_percent
    empl =  employment_at(Date.today)
    empl.percent if empl
  end
  
  # Returns the employement at the given date, nil if none is present.
  def employment_at(date)
    employments.find( :first, :conditions => 
      ['start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date] ) 
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
    if period
      options = clone_options options
      append_conditions(options[:conditions], ['work_date BETWEEN ? AND ?', period.startDate, period.endDate])
    end
    receiver.sum(:hours, options).to_f
  end
  
  def read_array_attribute(attribute)
    value = read_attribute(attribute)
    return [] if value.nil?
    value[1..-2].split(/,\s*/)
  end
  
  def write_array_attribute(attribute, value)
    value = [value] unless value.is_a? Array
    write_attribute(attribute, "{\"#{value.join("\", \"")}\"}")
  end
  
end
