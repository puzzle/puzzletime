# encoding: utf-8
# == Schema Information
#
# Table name: holidays
#
#  id            :integer          not null, primary key
#  holiday_date  :date             not null
#  musthours_day :float            not null
#


# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Holiday < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  include Comparable

  after_save :refresh

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
      if Holiday.weekend?(date) || Holiday.regular_holiday?(date)
        0
      else
        @@irregular_holidays.each do |holiday|
          return holiday.musthours_day if holiday.holiday_date == date
        end
        WorkingCondition.value_at(date, :must_hours_per_day)
      end
    end

    # Checks if date is a regular holiday
    def regular_holiday?(date)
      Settings.regular_holidays.any? do |day|
        date.day == day[0] && date.month == day[1]
      end
    end

    def irregular_holiday?(date)
      @@irregular_holidays.any? do |holiday|
        holiday.holiday_date == date
      end
    end

    # 0 is Sunday, 6 is Saturday
    def weekend?(date)
      wday = date.wday
      wday == 0 || wday == 6
    end

    def holiday?(date)
      weekend?(date) ||
        regular_holiday?(date) ||
        irregular_holiday?(date)
    end

    # returns all holidays for the given period which fall on a weekday
    def holidays(period)
      holidays = @@irregular_holidays.select { |holiday| period.include?(holiday.holiday_date) }
      irregulars = holidays.collect(&:holiday_date)
      regulars = regular_holidays(period)
      regulars.each do |holiday|
        holidays.push holiday unless irregulars.include?(holiday.holiday_date)
      end
      holidays
    end

    def regular_holidays(period)
      holidays = []
      years = period.start_date.year..period.end_date.year
      years.each do |year|
        Settings.regular_holidays.each do |day|
          regular = Date.civil(year, day[1], day[0])
          if period.include?(regular) && !weekend?(regular)
            holidays.push new(holiday_date: regular, musthours_day: 0)
          end
        end
      end
      holidays
    end

    def refresh
      @@irregular_holidays = Holiday.order('holiday_date')
      @@irregular_holidays = @@irregular_holidays.select do |holiday|
        !weekend?(holiday.holiday_date)
      end
    end

    private


    def workday_hours(period, must_hours_per_day)
      length = period.length
      weeks = length / 7
      hours = weeks * 5 * must_hours_per_day
      if length % 7 > 0
        lastPeriod = Period.new(period.start_date + weeks * 7, period.end_date)
        lastPeriod.step do |day|
          hours += must_hours_per_day unless weekend?(day)
        end
      end
      hours
    end
  end

  public

  def refresh
    Holiday.refresh
  end

  refresh

  def to_s
    holiday_date? ? "am #{I18n.l(holiday_date, format: :long)}" : ''
  end

  def <=>(other)
    holiday_date <=> other.holiday_date
  end
end
