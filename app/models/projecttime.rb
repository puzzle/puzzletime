# encoding: utf-8
# == Schema Information
#
# Table name: worktimes
#
#  id              :integer          not null, primary key
#  project_id      :integer
#  absence_id      :integer
#  employee_id     :integer
#  report_type     :string(255)      not null
#  work_date       :date             not null
#  hours           :float
#  from_start_time :time
#  to_end_time     :time
#  description     :text
#  billable        :boolean          default(TRUE)
#  booked          :boolean          default(FALSE)
#  type            :string(255)
#  ticket          :string(255)
#


class Projecttime < Worktime

  validates :project_id, presence: true
  validate :project_leaf
  validate :protect_booked, on: :update
  validate :validate_by_project

  before_destroy :protect_booked
  before_destroy :protect_frozen

  def self.valid_attributes
    super + [:account, :account_id, :description, :billable, :booked]
  end

  def self.account_label
    'Projekt'
  end

  def self.label
    'Projektzeit'
  end

  def account
    project
  end

  def account_id
    project_id
  end

  def account_id=(value)
    self.project_id = value
  end

  def set_project_defaults(id = nil)
    self.project_id = id
    self.project_id = Settings.default_project_id if project.nil?  # if id is nil or invalid, project is nil
    self.report_type = project.report_type if report_type < project.report_type
    self.billable = project.billable
  end

  def template(newWorktime = nil)
    newWorktime = super newWorktime
    newWorktime
  end

  ########### validation helpers ###########

  def validate_by_project
    project.validate_worktime(self) if project
  end

  def project_leaf
    p = project(true)
    errors.add(:project_id, 'Das angegebene Projekt enthält Subprojekte.') if p && p.sub_projects?
  end

  def protect_booked
    previous = Projecttime.find(id)
    if previous.booked && booked
      errors.add(:base, 'Verbuchte Arbeitszeiten können nicht verändert werden')
      return false
    end
  end

  def protect_frozen
    project.validate_worktime_frozen(self)
  end

end
