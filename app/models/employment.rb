#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: employments
#
#  id                     :integer          not null, primary key
#  employee_id            :integer
#  percent                :decimal(5, 2)    not null
#  start_date             :date             not null
#  end_date               :date
#  vacation_days_per_year :decimal(5, 2)
#  comment                :string
#

class Employment < ActiveRecord::Base
  DAYS_PER_YEAR = 365.25

  has_paper_trail

  belongs_to :employee
  has_many :employment_roles_employments,
           -> { order(percent: :desc) },
           dependent: :destroy

  accepts_nested_attributes_for :employment_roles_employments,
                                reject_if: :all_blank,
                                allow_destroy: true

  # All dependencies between the models are listed below.
  validates_by_schema
  validates :percent, inclusion: 0..200
  validates :employee_id, presence: true
  validates :vacation_days_per_year,
            numericality: { greater_or_equal_than: 0, less_than_or_equal_to: 366, allow_blank: true }
  validates :start_date, :end_date, timeliness: { date: true, allow_blank: true }
  validate :valid_period
  validates :employment_roles_employments, presence: true

  before_create :update_previous_end_date

  scope :list, -> { order('start_date DESC') }

  class << self

    def during(period)
      return all unless period

      conditions = ['']

      if period.start_date
        conditions.first << '("employments"."end_date" is NULL OR "employments"."end_date" >= ?)'
        conditions << period.start_date
      end

      if period.end_date
        conditions.first << ' AND ' if conditions.first.present?
        conditions.first << '"employments"."start_date" <= ?'
        conditions << period.end_date
      end

      where(*conditions)
    end

    def normalize_boundaries(employments, period)
      employments.each do |e|
        if period.start_date && e.start_date < period.start_date
          e.start_date = period.start_date
        end
        if period.end_date && (e.end_date.nil? || e.end_date > period.end_date)
          e.end_date = period.end_date
        end
      end
    end

  end

  def previous_employment
    @previous_employment ||=
      Employment.find_by('employee_id = ? AND start_date < ? AND end_date IS NULL',
                         employee_id, start_date)
  end

  def following_employment
    @following_employment ||=
      Employment.where('employee_id = ? AND start_date > ?', employee_id, start_date).
      order('start_date').
      first
  end

  def period
    Period.new(start_date, end_date ? end_date : Time.zone.today) if start_date
  end

  def percent_factor
    percent / 100.0
  end

  def vacations
    if vacation_days_per_year
      vacations_per_period(period, vacation_days_per_year)
    else
      WorkingCondition.sum_with(:vacation_days_per_year, period) do |p, v|
        vacations_per_period(p, v)
      end
    end
  end

  def musttime(p = period)
    (p & period).musttime * percent_factor
  end

  def to_s
    "die Anstellung vom #{date_label start_date} - #{date_label end_date}"
  end

  def date_label(date)
    date ? I18n.l(date) : 'offen'
  end

  private

  def vacations_per_period(period, days_per_year)
    period.vacation_factor_sum * percent_factor * days_per_year
  end

  # updates the end date of the previous employement
  def update_previous_end_date
    if previous_employment
      previous_employment.end_date = start_date - 1
      previous_employment.save!
    end
    if following_employment
      self.end_date ||= following_employment.start_date - 1
    end
    true
  end

  def valid_period
    if end_date && period && period.negative?
      errors.add(:base, 'Die Zeitspanne ist ungültig')
    elsif parallel_employments?
      errors.add(:base, 'Für diese Zeitspanne ist bereits eine andere Anstellung definiert')
    end
  end

  def parallel_employments?
    conditions = ['employee_id = ? ', employee_id]
    if id
      conditions[0] += ' AND id <> ? '
      conditions.push(id)
    end
    if end_date
      conditions[0] += ' AND (' \
        '(start_date <= ? AND (end_date >= ?' + (new_record? ? '' : ' OR end_date IS NULL') + ') ) OR ' \
        '(start_date <= ? AND (end_date >= ?' + (new_record? ? '' : ' OR end_date IS NULL') + ') ) OR ' \
        '(start_date >= ? AND end_date <= ? ))'
      conditions.push(start_date, start_date, end_date, end_date, start_date, end_date)
    else
      conditions[0] += ' AND (start_date = ? OR (start_date <= ? AND end_date >= ?))'
      conditions.push(start_date, start_date, start_date)
    end
    Employment.where(conditions).count > 0
  end
end
