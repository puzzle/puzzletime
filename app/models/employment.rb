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

  attr_accessor :final

  # All dependencies between the models are listed below.
  validates_inclusion_of :percent, in: 0..200, message: 'Die Prozente müssen angegeben werden'
  validates_presence_of :start_date, message: 'Das Start Datum muss angegeben werden'
  validates_presence_of :employee_id, message: 'Es muss ein Mitarbeiter angegeben werden'
  validates :start_date, :end_date, timeliness: { date: true, allow_blank: true }
  validate :valid_period

  before_validation :reset_end_date
  before_create :update_end_date
  belongs_to :employee


  scope :list, -> { order('start_date DESC') }

  def valid_period
    if end_date && period && period.negative?
      errors.add(:base, 'Die Zeitspanne ist ungültig')
    elsif parallel_employments?
      errors.add(:base, 'Für diese Zeitspanne ist bereits eine andere Anstellung definiert')
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
    if previous_employment
      previous_employment.end_date = start_date - 1
      previous_employment.save
    end
    if following_employment
      self.end_date = following_employment.start_date - 1
    end
  end

  def previous_employment
    @previous_employment ||=
      Employment.where('employee_id = ? AND start_date < ? AND end_date IS NULL',
                       employee_id, start_date).
                 first
  end

  def following_employment
    @following_employment ||=
      Employment.where('employee_id = ? AND start_date > ?', employee_id, start_date).
                 order('start_date').
                 first
  end

  def period
    return Period.retrieve(start_date, end_date ? end_date : Date.today) if start_date
  end

  def percent_factor
    percent / 100.0
  end

  def vacations
    WorkingCondition.sum_of(:vacation_days_per_year, period) do |p, v|
      p.length / 365.25 * percent_factor * v
    end
  end

  def musttime
    period.musttime * percent_factor
  end

  def to_s
    "die Anstellung vom #{date_label start_date} - #{date_label end_date}"
  end

  def date_label(date)
    date ? I18n.l(date) : 'offen'
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
