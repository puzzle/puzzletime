# encoding: utf-8
# == Schema Information
#
# Table name: employees
#
#  id                    :integer          not null, primary key
#  firstname             :string(255)      not null
#  lastname              :string(255)      not null
#  shortname             :string(3)        not null
#  passwd                :string(255)
#  email                 :string(255)      not null
#  management            :boolean          default(FALSE)
#  initial_vacation_days :float
#  ldapname              :string(255)
#  eval_periods          :string(3)        is an Array
#  departement_id        :integer
#

class Employee < ActiveRecord::Base

  include Evaluatable
  include ReportType::Accessors
  extend Conditioner
  extend Manageable

  # All dependencies between the models are listed below.
  has_and_belongs_to_many :employee_lists

  has_many :employments, dependent: :destroy
  has_many :projectmemberships,
           dependent: :destroy
  has_many :projects,
           -> { where(projectmemberships: { active: true }) },
           through: :projectmemberships
  has_many :clients, -> { order('shortname') }, through: :projects
  has_many :managed_projects,
           -> { where(projectmemberships: { projectmanagement: true, active: true }) },
           class_name: 'Project',
           through: :projectmemberships
  has_many :absences,
           -> { order('name').uniq },
           through: :worktimes
  has_many :worktimes
  has_many :overtime_vacations, dependent: :destroy
  has_one :running_project,
          -> { where(report_type: AutoStartType::INSTANCE.key) },
          class_name: 'Projecttime'

  # Validation helpers.
  validates_presence_of :firstname, message: 'Der Vorname muss angegeben werden'
  validates_presence_of :lastname, message: 'Der Nachname muss angegeben werden'
  validates_presence_of :shortname, message: 'Das Kürzel muss angegeben werden'
  validates_presence_of :email, message: 'Die Email Adresse muss angegeben werden'         # Required by database
  validates_uniqueness_of :shortname, message: 'Dieses Kürzel wird bereits verwendet'
  validates_uniqueness_of :ldapname, allow_blank: true, message: 'Dieser LDAP Name wird bereits verwendet'
  validate :periods_format

  before_destroy :protect_worktimes

  scope :list, -> { order('lastname', 'firstname') }

  # Tries to login a user with the passed data.
  # Returns the logged-in Employee or nil if the login failed.
  def self.login(username, pwd)
    find_by_shortname_and_passwd(username.upcase, encode(pwd)) ||
    LdapAuthenticator.new.login(username, pwd)
  end

  def self.employed_ones(period)
    joins('left join employments em on em.employee_id = employees.id').
    where('(em.end_date IS null or em.end_date >= ?) AND em.start_date <= ?',
          period.startDate, period.endDate).
    list.
    uniq
  end

  ##### interface methods for Manageable #####

  def self.puzzlebase_map
    Puzzlebase::Employee
  end

  ##### interface methods for Evaluatable #####

  def to_s
    lastname + ' ' + firstname
  end

  def self.worktimes
    Worktime.all
  end

  ##### helper methods #####

  # Whether this Employee is a project manager
  def project_manager?
    managed_projects.exists?
  end

  # Accessor for the initial vacation days. Default is 0.
  def initial_vacation_days
    super || 0
  end

  def before_create
    self.passwd = ''    # disable password login
    projectmemberships.build(project_id: Settings.default_project_id)
  end

  def check_passwd(pwd)
    passwd == Employee.encode(pwd)
  end

  def set_passwd(pwd)
    update_attributes!(passwd: Employee.encode(pwd))
  end

  # Sums the worktimes of all managed projects.
  def sum_managed_projects_worktime(period)
    sql = 'SELECT sum(hours) AS sum ' \
          'FROM (((employees E LEFT JOIN projectmemberships PM ON E.id = PM.employee_id) ' +
	        ' LEFT JOIN projects P ON PM.project_id = P.id)' +
          ' LEFT JOIN projects C ON P.id = ANY (C.path_ids))' +
          ' LEFT JOIN worktimes T ON C.id = T.project_id ' +
          "WHERE E.id = #{id} AND PM.projectmanagement"
    sql += " AND T.work_date BETWEEN '#{period.startDate}' AND '#{period.endDate}'" if period
    self.class.connection.select_value(sql).to_f
  end

  # parent projects this employee ever worked on
  def alltime_projects
    Project.select("DISTINCT projects.*").
            joins('RIGHT JOIN projects leaves ON leaves.path_ids[1] = projects.id').
            joins('RIGHT JOIN worktimes ON worktimes.project_id = leaves.id').
            where(worktimes: { employee_id: id} ).
            where('projects.id IS NOT NULL').
            list
  end

  def worked_on_projects
    Project.find_by_sql ['SELECT DISTINCT pw.* FROM worktimes w ' \
                'LEFT JOIN projects pw ON w.project_id = pw.id ' \
                'WHERE w.employee_id = ? AND pw.id IS NOT NULL ' \
                'ORDER BY pw.path_shortnames', id]
  end

  # the leaf projects of the given list or of the current membership projects
  def leaf_projects(list = nil)
    list ||= projects
    list.collect { |p| p.leaves }.flatten.uniq
  end

  def statistics
    @statistics ||= EmployeeStatistics.new(self)
  end

  ######### employment information ######################

  # Returns the current employement percent value.
  # Returns nil if no current employement is present.
  def current_percent
    percent(Date.today)
  end

  # Returns the employment percent value for a given employment date
  def percent(date)
    empl = employment_at(date)
    empl.percent if empl
  end

  # Returns the employement at the given date, nil if none is present.
  def employment_at(date)
    employments.where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date).first
  end

  def self.encode(pwd)
    Digest::SHA1.hexdigest(pwd)
    # logger.info "Hash of password: #{Digest::SHA1.hexdigest(pwd)}"
  end

  def eval_periods
    super || []
  end

  private

  def periods_format
    validate_periods_format(:eval_periods, eval_periods)
  end

  def validate_periods_format(attr, periods)
    periods.each do |p|
      unless p =~ /^\-?\d[dwmqy]?$/
        errors.add(attr, 'ist nicht gültig')
      end
    end
  end

end
