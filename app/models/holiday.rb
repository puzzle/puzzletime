#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: holidays
#
#  id            :integer          not null, primary key
#  holiday_date  :date             not null
#  musthours_day :float            not null
#

class Holiday < ActiveRecord::Base

  include ActionView::Helpers::NumberHelper
  include Comparable

  after_save :clear_cache
  after_destroy :clear_cache

  validates_by_schema
  validates :holiday_date,
            uniqueness: { message: 'Pro Datum ist nur ein Feiertag erlaubt' },
            timeliness: { date: true, allow_blank: true }

  scope :list, -> { order('holiday_date DESC') }

  class << self
    def period_musttime(period)
      WorkingCondition.sum_with(:must_hours_per_day, period) do |p, h|
        hours = workday_hours(p, h)
        holidays(p).each do |holiday|
          hours -= h - holiday.musthours_day
        end
        hours
      end
    end

    # Collection of functions to check if date is holiday or not
    def musttime(date)
      if Holiday.weekend?(date)
        0
      else
        cached[date] || WorkingCondition.value_at(date, :must_hours_per_day)
      end
    end

    def irregular_holiday?(date)
      cached.keys.include?(date)
    end

    # 0 is Sunday, 6 is Saturday
    def weekend?(date)
      wday = date.wday
      wday.zero? || wday == 6
    end

    def holiday?(date)
      weekend?(date) || irregular_holiday?(date)
    end

    # returns all holidays for the given period which fall on a weekday
    def holidays(period)
      irregulars = cached.keys.select { |day| period.include?(day) }
      irregulars.collect { |day| new(holiday_date: day, musthours_day: cached[day]) }
    end

    def cached
      RequestStore.store[model_name.route_key] ||=
        Rails.cache.fetch(model_name.route_key) do
          Hash[Holiday.order('holiday_date').
               reject { |h| weekend?(h.holiday_date) }.
               collect { |h| [h.holiday_date, h.musthours_day] }]
        end
    end

    def clear_cache
      RequestStore.store[model_name.route_key] = nil
      Rails.cache.clear(model_name.route_key)
      true
    end

    private

    def workday_hours(period, must_hours_per_day)
      length = period.length
      weeks = length / 7
      hours = weeks * 5 * must_hours_per_day
      if length % 7 > 0
        last_period = Period.new(period.start_date + weeks * 7, period.end_date)
        last_period.step do |day|
          hours += must_hours_per_day unless weekend?(day)
        end
      end
      hours
    end

  end

  def clear_cache
    Holiday.clear_cache
  end

  def to_s
    holiday_date? ? "am #{I18n.l(holiday_date, format: :long)}" : ''
  end

  def <=>(other)
    return unless other.is_a?(Holiday)
    holiday_date <=> other.holiday_date
  end
end
