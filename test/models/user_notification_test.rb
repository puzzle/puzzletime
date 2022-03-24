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

require 'test_helper'

class UserNotificationTest < ActiveSupport::TestCase
  test 'list during for current period' do
    monday = Time.zone.today.at_beginning_of_week
    UserNotification.create!(date_from: monday - 2.days, date_to: monday, message: 'bar')
    UserNotification.create!(date_from: monday - 5.days, date_to: monday - 1.day, message: 'foo')
    UserNotification.create!(date_from: monday + 6.days, date_to: monday + 10.days, message: 'baz')
    Holiday.create!(holiday_date: monday + 4.days, musthours_day: 0)

    messages = UserNotification.list_during.collect(&:message)
    assert_includes messages, 'bar'
    assert_not_includes messages, 'foo'
    assert_includes messages, 'baz'
  end
end
