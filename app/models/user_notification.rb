#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

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
  validates_by_schema
  validates :date_from, :date_to, timeliness: { date: true, allow_blank: true }
  validate :validate_period

  scope :list, -> { order('date_from DESC, date_to DESC') }

  class << self
    def list_during(period = nil, current_user = nil)
      # only show notifications for the current week
      return if period

      period = Period.current_week
      custom = list.where('date_from BETWEEN ? AND ? OR date_to BETWEEN ? AND ?',
                          period.start_date, period.end_date,
                          period.start_date, period.end_date).
               reorder('date_from')
      list = custom.to_a.concat(holiday_notifications(period))
      list.sort!
    end

    def holiday_notifications(period = nil)
      period ||= Period.current_week
      regular = Holiday.holidays(period)
      regular.collect! { |holiday| new_holiday_notification(holiday) }
    end

    private

    def new_holiday_notification(holiday)
      new(date_from: holiday.holiday_date,
          date_to: holiday.holiday_date,
          message: holiday_message(holiday))
    end

    def holiday_message(holiday)
      I18n.l(holiday.holiday_date, format: :long) +
        ' ist ein Feiertag (' + format('%01.2f', holiday.musthours_day).to_s +
        ' Stunden Sollarbeitszeit)'
    end
  end

  def <=>(other)
    return unless other.is_a?(UserNotification)

    date_from <=> other.date_from
  end

  def to_s
    message.truncate(30)
  end

  private

  def validate_period
    if date_from && date_to && date_from > date_to
      errors.add(:date_to, 'Enddatum muss nach Startdatum sein.')
    end
  end
end
