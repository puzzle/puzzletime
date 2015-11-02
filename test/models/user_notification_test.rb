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

  test 'worktimes commit notification not shown before end of month' do
    ActiveSupport::TimeZone.any_instance.stubs(today: Date.new(2015, 9, 23))
    e = employees(:pascal)
    assert !UserNotification.show_worktimes_commit_notification?(e)
  end

  test 'worktimes commit notification shown at end of month' do
    ActiveSupport::TimeZone.any_instance.stubs(today: Date.new(2015, 9, 24))
    e = employees(:pascal)
    assert UserNotification.show_worktimes_commit_notification?(e)
  end

  test 'worktimes commit notification shown at beginning of month' do
    ActiveSupport::TimeZone.any_instance.stubs(today: Date.new(2015, 9, 3))
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-7-31')
    assert UserNotification.show_worktimes_commit_notification?(e)
  end

  test 'worktimes commit notification not shown after beginning of month' do
    ActiveSupport::TimeZone.any_instance.stubs(today: Date.new(2015, 9, 4))
    e = employees(:pascal)
    assert !UserNotification.show_worktimes_commit_notification?(e)
  end

  test 'worktimes commit notification not shown if committed this period end of month' do
    ActiveSupport::TimeZone.any_instance.stubs(today: Date.new(2015, 9, 29))
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-9-30')
    assert !UserNotification.show_worktimes_commit_notification?(e)
  end

  test 'worktimes commit notification not shown if committed this period beginning of month' do
    ActiveSupport::TimeZone.any_instance.stubs(today: Date.new(2015, 10, 2))
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-9-30')
    assert !UserNotification.show_worktimes_commit_notification?(e)
  end

  test 'worktimes commit notification not shown if committed next period beginning of month' do
    ActiveSupport::TimeZone.any_instance.stubs(today: Date.new(2015, 10, 2))
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-10-31')
    assert !UserNotification.show_worktimes_commit_notification?(e)
  end

end
