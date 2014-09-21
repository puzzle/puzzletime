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

  # Validation helpers
  validates_presence_of :date_from, message: 'Eine Startdatum muss angegeben werden'
  validates_presence_of :message, message: 'Eine Nachricht muss angegeben werden'
  validates :date_from, :date_to, timeliness: { date: true, allow_blank: true }
  validate :validate_period

  scope :list, -> { order('date_from DESC, date_to DESC') }


  def self.list_during(period = nil)
    current = period.nil?
    period ||= Period.current_week
    custom = list.where('date_from BETWEEN ? AND ? OR date_to BETWEEN ? AND ?',
                        period.start_date, period.end_date,
                        period.start_date, period.end_date).
                  reorder('date_from')
    list = custom.concat(holiday_notifications(period))
    list.sort!
  end

  def self.holiday_notifications(period = nil)
    period ||= Period.current_week
    regular = Holiday.holidays(period)
    regular.collect! { |holiday| new_holiday_notification(holiday) }
  end

  private

  def self.new_holiday_notification(holiday)
    new date_from: holiday.holiday_date,
        date_to: holiday.holiday_date,
        message: holiday_message(holiday)
  end

  def self.holiday_message(holiday)
    I18n.l(holiday.holiday_date, format: :long) +
      ' ist ein Feiertag (' + ('%01.2f' % holiday.musthours_day).to_s +
      ' Stunden Sollarbeitszeit)'
  end

  public

  def <=>(other)
    date_from <=> other.date_from
  end

  def to_s
    message.truncate(30)
  end

  def validate_period
    if date_from && date_to && date_from > date_to
      errors.add(:date_to, 'Enddatum muss nach Startdatum sein.')
    end
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
