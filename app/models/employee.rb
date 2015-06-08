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
#  eval_periods          :string           is an Array
#  department_id         :integer
#

class Employee < ActiveRecord::Base

  include Evaluatable
  include ReportType::Accessors
  extend Conditioner

  # All dependencies between the models are listed below.
  belongs_to :department

  has_and_belongs_to_many :employee_lists
  has_and_belongs_to_many :invoices

  has_many :employments, dependent: :destroy
  has_many :absences,
           -> { order('name').uniq },
           through: :worktimes
  has_many :worktimes
  has_many :overtime_vacations, dependent: :destroy
  has_many :managed_orders, class_name: 'Order', foreign_key: :responsible_id, dependent: :nullify
  has_many :order_team_members, dependent: :destroy
  has_one :running_time,
          -> { where(report_type: AutoStartType::INSTANCE.key) },
          class_name: 'Ordertime'

  # Validation helpers.
  validates_presence_of :firstname, message: 'Der Vorname muss angegeben werden'
  validates_presence_of :lastname, message: 'Der Nachname muss angegeben werden'
  validates_presence_of :shortname, message: 'Das Kürzel muss angegeben werden'
  validates_presence_of :email, message: 'Die Email Adresse muss angegeben werden'         # Required by database
  validates_uniqueness_of :shortname, case_sensitive: false, message: 'Dieses Kürzel wird bereits verwendet'
  validates_uniqueness_of :ldapname, allow_blank: true, case_sensitive: false, message: 'Dieser LDAP Name wird bereits verwendet'
  validate :periods_format

  protect_if :worktimes, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Arbeitszeiten zugeordnet sind'

  scope :list, -> { order('lastname', 'firstname') }

  class << self
    # Tries to login a user with the passed data.
    # Returns the logged-in Employee or nil if the login failed.
    def login(username, pwd)
      find_by_shortname_and_passwd(username.upcase, encode(pwd)) ||
      LdapAuthenticator.new.login(username, pwd)
    end

    def employed_ones(period)
      joins('left join employments em on em.employee_id = employees.id').
      where('(em.end_date IS null or em.end_date >= ?) AND em.start_date <= ?',
            period.start_date, period.end_date).
      list.
      uniq
    end

    def worktimes
      Worktime.all
    end

    def encode(pwd)
      Digest::SHA1.hexdigest(pwd)
      # logger.info "Hash of password: #{Digest::SHA1.hexdigest(pwd)}"
    end
  end

  ##### helper methods #####

  def to_s
    "#{lastname} #{firstname}"
  end

  def order_responsible?
    @order_responsible ||= managed_orders.exists?
  end

  # Accessor for the initial vacation days. Default is 0.
  def initial_vacation_days
    super || 0
  end

  def eval_periods
    super || []
  end

  def before_create
    self.passwd = ''    # disable password login
  end

  def check_passwd(pwd)
    passwd == Employee.encode(pwd)
  end

  def set_passwd(pwd)
    update_attributes!(passwd: Employee.encode(pwd))
  end

  # main work items this employee ever worked on
  def alltime_main_work_items
    WorkItem.select("DISTINCT work_items.*").
             joins('RIGHT JOIN work_items leaves ON leaves.path_ids[1] = work_items.id').
             joins('RIGHT JOIN worktimes ON worktimes.work_item_id = leaves.id').
             where(worktimes: { employee_id: id} ).
             where('work_items.id IS NOT NULL').
             list
  end

  def alltime_leaf_work_items
    WorkItem.select("DISTINCT work_items.*").
             joins('RIGHT JOIN worktimes ON worktimes.work_item_id = work_items.id').
             where(worktimes: { employee_id: id} ).
             where('work_items.id IS NOT NULL').
             list
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
