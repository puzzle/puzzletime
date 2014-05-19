# encoding: utf-8
# == Schema Information
#
# Table name: user_notifications
#
#  id        :integer          not null, primary key
#  date_from :date             not null
#  date_to   :date
#  message   :text             not null
#



class UserNotification < ActiveRecord::Base

  include Comparable
  extend Manageable

  # Validation helpers
  before_validation DateFormatter.new('date_from', 'date_to')
  validates_presence_of :date_from, message: 'Eine Startdatum muss angegeben werden'
  validates_presence_of :message, message: 'Eine Nachricht muss angegeben werden'
  validate :validate_period


  def self.list_during(period = nil)
    current = period.nil?
    period ||= Period.currentWeek
    custom = list(conditions: ['date_from BETWEEN ? AND ? OR date_to BETWEEN ? AND ?',
                               period.startDate, period.endDate,
                               period.startDate, period.endDate],
                  order: 'date_from')
    list = custom.concat(holiday_notifications(period))
    list.push currentCompletionNotification if current && month_end?
    list.sort!
  end

  def self.holiday_notifications(period = nil)
    period ||= Period.currentWeek
    regular = Holiday.holidays(period)
    regular.collect! { |holiday| newHolidayNotification(holiday) }
  end


  private

  def self.currentCompletionNotification
    last_day = month_end
    new date_from: last_day,
        date_to: last_day,
        message: 'Bitte Ende Monat Projekte komplettieren.'
  end

  def self.newHolidayNotification(holiday)
    new date_from: holiday.holiday_date,
        date_to: holiday.holiday_date,
        message: holidayMessage(holiday)
  end

  def self.holidayMessage(holiday)
    I18n.l(holiday.holiday_date, format: LONG_DATE_FORMAT) +
      ' ist ein Feiertag (' + ('%01.2f' % holiday.musthours_day).to_s +
      ' Stunden Sollarbeitszeit)'
  end

  def self.month_end
    last_day = Date.today
    if last_day.mday > 12
      last_day = last_day.last_month
    end
    last_day.end_of_month
  end

  def self.month_end?
    today = Date.today.mday
    today > DISPLAY_COMPLETION[0] || today < DISPLAY_COMPLETION[1]
  end

  public

  def <=>(other)
    date_from <=> other.date_from
  end

  ##### interface methods for Manageable #####

  def label
    "die Nachricht '#{message}'"
  end

  def self.labels
    %w(Die Nachricht Nachrichten)
  end

  def self.orderBy
    'date_from DESC, date_to DESC'
  end

  def validate_period
    errors.add(:date_to, 'Enddatum muss nach Startdatum sein.') if date_from > date_to
  end

  #### caching #####

  def date_to
    # cache date to prevent endless string_to_date conversion
    @date_to ||= read_attribute(:date_to)
  end

  def date_to=(value)
    write_attribute(:date_to, value)
    @date_to = nil
  end

  def date_from
    # cache date to prevent endless string_to_date conversion
    @date_from ||= read_attribute(:date_from)
  end

  def date_from=(value)
    write_attribute(:date_from, value)
    @date_from = nil
  end

end
