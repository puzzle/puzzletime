# encoding: utf-8
# == Schema Information
#
# Table name: worktimes
#
#  id              :integer          not null, primary key
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
#  work_item_id    :integer
#

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Worktime < ActiveRecord::Base

  H_M = /^(\d*):([0-5]\d)/

  include ReportType::Accessors
  include Conditioner

  belongs_to :employee
  belongs_to :absence
  belongs_to :work_item

  validates_presence_of :employee_id, message: 'Ein Mitarbeiter muss vorhanden sein'
  validates :work_date, timeliness: { date: true }
  validate :validate_by_report_type

  before_validation :store_hours

  scope :in_period, ->(period) do
    if period
      if period.start_date && period.end_date
        where('work_date BETWEEN ? AND ?', period.start_date, period.end_date)
      elsif period.start_date
        where('work_date >= ?', period.start_date)
      elsif period.end_date
        where('work_date <= ?', period.end_date)
      else
        all
      end
    else
      all
    end
  end

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
  # TODO rename to accounting_post, okay?
  def account
    nil
  end

  # account id, default nil
  def account_id
  end

  # sets the account id.
  # overwrite in subclass
  def account_id=(value)
  end

  def order
    work_item.try(:order)
  end

  # set the hours, either as number or as a string with the format
  # h:mm or h.dd (8:45 <-> 8.75)
  def hours=(value)
    if md = H_M.match(value.to_s)
      value = md[1].to_i + md[2].to_i / 60.0
    end
    write_attribute 'hours', value.to_f
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
    report_type.time_string(self) if report_type
  end

  # Returns the date formatted according to the report type
  def date_string
    report_type.date_string(work_date)
  end

  def work_date
    # cache date to prevent endless string_to_date conversion
    @work_date ||= read_attribute(:work_date)
  end

  def work_date=(value)
    write_attribute(:work_date, value)
    @work_date = nil
  end

  ###################  TESTS  ####################

  # Whether this Worktime is for an absence or not
  def absence?
    false
  end

  # Whether the report typ of this Worktime contains start and stop times
  def start_stop?
    report_type.start_stop? if report_type
  end

  # Whether this Worktime contains the passed attribute
  def has_column?(attr)
    self.class.valid_attributes.include? attr
  end

  ##################  HELPERS  ####################

  # Returns a copy of this Worktime with default values set
  def template(newWorktime = nil)
    newWorktime ||= self.class.new
    newWorktime.from_start_time = report_type.is_a?(StartStopType) ?
                 to_end_time : Time.zone.now.change(hour: Settings.defaults.start_hour)
    newWorktime.report_type = report_type
    newWorktime.work_date = work_date
    newWorktime.account_id = account_id
    newWorktime.billable = billable
    newWorktime.employee_id = employee_id
    newWorktime.work_item_id = work_item_id
    newWorktime
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
    report_type.validate_worktime(self) if report_type
  end

  # Store hour information from start/stop times.
  def store_hours
    if start_stop? && from_start_time && to_end_time
      self.hours = (to_end_time.seconds_since_midnight - from_start_time.seconds_since_midnight) / 3600.0
    end
    self.work_date = Date.today if report_type.kind_of? AutoStartType
  end

  # Name of the corresponding controller
  def controller
    self.class.model_name.route_key
  end

  def to_s
    "#{time_string} #{self.class.model_name.human} #{'für ' + account.label_verbose if account}"
  end

  ##################  CLASS METHODS   ######################

  # Returns an Array of the valid attributes for this Worktime
  def self.valid_attributes
    [:work_date, :hours, :from_start_time, :to_end_time, :employee_id, :report_type]
  end

  # label for the account class
  # overwrite in subclass
  def self.account_label
    ''
  end

  #######################  CLASS METHODS FOR EVALUATABLE  ####################

  def self.worktimes
    self
  end

  private

  # allow time formats such as 14, 1400, 14:00 and 14.0 (1430, 14:30, 14.5)
  def write_converted_time(attribute, value)
    value = I18n.l(value, format: :time) if value.kind_of? Time
    if value.kind_of?(String) && ! (value =~ H_M)
      if value.size > 0 && value =~ /^\d*\.?\d*$/
        # military time: 1400
        if value.size > 2 && !value.include?('.')
          hour = value.to_i / 100
          value = hour.to_s + ':' + (value.to_i - hour * 100).to_s
        else
          value = value.to_i.to_s + ':' + ((value.to_f - value.to_i) * 60).to_i.to_s
        end
      else
        value = nil
      end
    end
    write_attribute attribute, value
  end

end
