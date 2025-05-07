# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: worktimes
#
#  id                   :integer          not null, primary key
#  billable             :boolean          default(TRUE)
#  description          :text
#  from_start_time      :time
#  hours                :float
#  internal_description :text
#  meal_compensation    :boolean          default(FALSE), not null
#  report_type          :string(255)      not null
#  ticket               :string(255)
#  to_end_time          :time
#  type                 :string(255)
#  work_date            :date             not null
#  absence_id           :integer
#  employee_id          :integer
#  invoice_id           :integer
#  work_item_id         :integer
#
# Indexes
#
#  index_worktimes_on_invoice_id  (invoice_id)
#  worktimes_absences             (absence_id,employee_id,work_date)
#  worktimes_employees            (employee_id,work_date)
#  worktimes_work_items           (work_item_id,employee_id,work_date)
#
# Foreign Keys
#
#  fk_times_absences   (absence_id => absences.id) ON DELETE => cascade
#  fk_times_employees  (employee_id => employees.id) ON DELETE => cascade
#
# }}}

class Worktime < ApplicationRecord
  H_M = /^(\d*):([0-5]\d)/

  include ReportType::Accessors
  include Conditioner

  class_attribute :account_label

  belongs_to :employee, optional: false
  belongs_to :absence, optional: true
  belongs_to :work_item, optional: true
  belongs_to :invoice, optional: true

  validates_by_schema
  validates :work_date, timeliness: { date: true }
  validate :validate_by_report_type

  before_validation :guess_report_type
  before_validation :store_hours
  before_validation :strip_ticket

  scope :in_period, (lambda do |period|
    if period
      where(period.where_condition('work_date'))
    else
      all
    end
  end)

  scope :billable, -> { where(billable: true) }

  class << self
    # The displayed label of this object.
    def label
      'Zeit'
    end

    # A more complete label, defaults to the normal label method.
    def label_verbose
      label
    end
  end

  ###############  ACCESSORS  ##################

  # account this worktime is booked for.
  # defined in subclasses, either WorkItem or Absence
  def account
    nil
  end

  # account id, default nil
  def account_id; end

  # sets the account id.
  # overwrite in subclass
  def account_id=(_value); end

  # set the hours, either as number or as a string with the format
  # h:mm or h.dd (8:45 <-> 8.75)
  def hours=(value)
    if (md = H_M.match(value.to_s))
      value = md[1].to_i + (md[2].to_i / 60.0)
    end
    self['hours'] = value.to_f
  end

  # set the start time, either as number or as a string with the format
  # h:mm or h.dd (8:45 <-> 8.75)
  def from_start_time=(value)
    write_converted_time 'from_start_time', value
  end

  # set the end time, either as number or as a string with the format
  # h:mm or h.dd (8:45 <-> 8.75)
  def to_end_time=(value)
    write_converted_time 'to_end_time', value
  end

  # Returns a human readable String of the time information contained in this Worktime.
  def time_string
    report_type&.time_string(self)
  end

  # Returns the date formatted according to the report type
  def date_string
    report_type.date_string(work_date)
  end

  ###################  TESTS  ####################

  # Whether this Worktime is for an absence or not
  def absence?
    false
  end

  # Whether the report typ of this Worktime contains start and stop times
  def start_stop?
    report_type&.start_stop?
  end

  ##################  HELPERS  ####################

  # Returns a copy of this Worktime with default values set
  def template(new_worktime = nil)
    new_worktime ||= self.class.new
    new_worktime.from_start_time =
      if report_type.is_a?(ReportType::StartStopType)
        to_end_time
      else
        Time.zone.now.change(hour: Settings.defaults.start_hour)
      end
    new_worktime.report_type = report_type
    new_worktime.work_date = work_date
    new_worktime.account_id = account_id
    new_worktime.billable = billable
    new_worktime.meal_compensation = meal_compensation
    new_worktime.employee_id = employee_id
    new_worktime.work_item_id = work_item_id
    new_worktime
  end

  def copy_from(other)
    self.report_type      = other.report_type
    self.work_date        = other.work_date
    self.hours            = other.hours
    self.from_start_time  = other.from_start_time
    self.to_end_time      = other.to_end_time
  end

  # Copies the report_type and the time information from an other Worktime
  def copy_times_from(other)
    self.report_type = other.report_type
    other.report_type.copy_times(other, self)
  end

  # Validate callback before saving
  def validate_by_report_type
    report_type&.validate_worktime(self)
  end

  def guess_report_type
    if from_start_time || to_end_time
      self.report_type = ReportType::StartStopType::INSTANCE
    else
      self.from_start_time = nil
      self.to_end_time = nil
      self.report_type = ReportType::HoursDayType::INSTANCE
    end
  end

  # Store hour information from start/stop times.
  def store_hours
    if start_stop?
      if from_start_time && to_end_time
        value = (to_end_time.seconds_since_midnight - from_start_time.seconds_since_midnight) / 3600.0
        self.hours = value if (hours.to_f - value).abs > 0.0001 # don't cause a change for every minor diff
      else
        self.hours = nil
      end
    end
    self.work_date = Time.zone.today if report_type.is_a? ReportType::AutoStartType
  end

  def strip_ticket
    self.ticket = ticket.strip if ticket.present?
  end

  # Name of the corresponding controller
  def controller
    self.class.model_name.route_key
  end

  def to_s
    account_part = "für #{account.label_verbose}" if account
    "#{time_string} #{self.class.model_name.human} #{account_part}"
  end

  #######################  CLASS METHODS FOR EVALUATABLE  ####################

  def self.worktimes
    self
  end

  def worktimes_committed?
    committed_at = employee.committed_worktimes_at

    committed_at &&
      ((work_date && committed_at >= work_date) ||
       (work_date_was && committed_at >= work_date_was))
  end

  private

  # allow time formats such as 14, 1400, 14:00 and 14.0 (1430, 14:30, 14.5)
  def write_converted_time(attribute, value)
    value = I18n.l(value, format: :time) if value.is_a? Time
    if value.is_a?(String) && value !~ H_M
      if !value.empty? && value =~ /^\d*\.?\d*$/
        # military time: 1400
        if value.size > 2 && value.exclude?('.')
          hour = value.to_i / 100
          value = "#{hour}:#{value.to_i - (hour * 100)}"
        else
          value = "#{value.to_i}:#{((value.to_f - value.to_i) * 60).to_i}"
        end
      else
        value = nil
      end
    end
    self[attribute] = value
  end
end
