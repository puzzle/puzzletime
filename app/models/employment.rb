# encoding: utf-8
# == Schema Information
#
# Table name: employments
#
#  id          :integer          not null, primary key
#  employee_id :integer
#  percent     :decimal(5, 2)    not null
#  start_date  :date             not null
#  end_date    :date
#


# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Employment < ActiveRecord::Base

  extend Manageable

  attr_accessor :final

  # All dependencies between the models are listed below.
  validates_inclusion_of :percent, in: 0..200, message: 'Die Prozente m&uuml;ssen angegeben werden'
  validates_presence_of :start_date, message: 'Das Start Datum muss angegeben werden'
  validates_presence_of :employee_id, message: 'Es muss ein Mitarbeiter angegeben werden'
  validate :valid_period

  before_validation :reset_end_date
  before_create :update_end_date
  belongs_to :employee

  before_validation DateFormatter.new('start_date', 'end_date')

  scope :list, -> { order('start_date DESC') }

  def valid_period
    if end_date && period && period.negative?
      errors.add_to_base('Die Zeitspanne ist ung&uuml;ltig')
    elsif parallel_employments?
      errors.add_to_base('F&uuml;r diese Zeitspanne ist bereits eine andere Anstellung definiert')
    end
  end

  def reset_end_date
    write_attribute('end_date', nil) unless final
  end

  def final
    @final = (end_date) if @final.nil?
    @final
  end

  def final=(value)
    value = value.to_i > 0 unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
    @final = value
  end

  def update_attributes(attr)
    self.final = attr[:final]
    super(attr)
  end

  # updates the end date of the previous employement
  def update_end_date
    previous_employment = Employment.where('employee_id = ? AND start_date < ? AND end_date IS NULL', employee_id, start_date).first
    if previous_employment
      previous_employment.end_date = start_date - 1
      previous_employment.save
    end
    later_employment = Employment.where('employee_id = ? AND start_date > ?', employee_id, start_date).order('start_date').first
    if later_employment
      self.end_date = later_employment.start_date - 1
    end
  end

  def period
    return Period.retrieve(start_date, end_date ? end_date : Date.today) if start_date
  end

  def percent_factor
    percent / 100.0
  end

  def vacations
    period.length / 365.25 * VACATION_DAYS_PER_YEAR * percent_factor
  end

  def musttime
    period.musttime * percent_factor
  end

  ##### cache dates for performance reasons  ######

  def start_date
  	 @start_date ||= read_attribute(:start_date)
  end

  def end_date
  	 @end_date ||= read_attribute(:end_date)
  end

  def start_date=(value)
  	 write_attribute(:start_date, value)
	   @start_date = nil
  end

  def end_date=(value)
  	 write_attribute(:end_date, value)
	   @end_date = nil
  end

  ##### interface methods for Manageable #####

  def self.puzzlebase_map
    Puzzlebase::Employment
  end

  def label
    "die Anstellung vom #{date_label start_date} - #{date_label end_date}"
  end

  def self.labels
    %w(Die Anstellung Anstellungen)
  end

  def self.order_by
    'start_date DESC'
  end

  def self.column_type(col)
    return :boolean if col == :final
    super(col)
  end

  def date_label(date)
    date ? date.strftime(DATE_FORMAT) : 'offen'
  end

  private

  def parallel_employments?
    conditions = ['employee_id = ? ', employee_id]
    if id
      conditions[0] += ' AND id <> ? '
      conditions.push(id)
    end
    if end_date
      conditions[0] += ' AND (' \
         '(start_date <= ? AND (end_date >= ?' + (new_record? ? '' : ' OR end_date IS NULL') + ') ) OR' +
        '(start_date <= ? AND (end_date >= ?' + (new_record? ? '' : ' OR end_date IS NULL') + ') ) OR ' +
        '(start_date >= ? AND end_date <= ? ))'
      conditions.push(start_date, start_date, end_date, end_date, start_date, end_date)
    else
      conditions[0] += ' AND (start_date = ? OR (start_date <= ? AND end_date >= ?))'
      conditions.push(start_date, start_date, start_date)
    end
    Employment.where(conditions).count > 0
  end

end
