# frozen_string_literal: true

require 'test_helper'

class EmployeeMailerTest < ActionMailer::TestCase
  attr_reader :order, :accounting_post1, :accounting_post2

  setup do
    @order = Fabricate(:order,
                       responsible: employees(:next_year_pablo))
    @accounting_post1 = Fabricate(:accounting_post,
                                  work_item: Fabricate(:work_item, parent_id: order.work_item_id),
                                  offered_hours: 100,
                                  offered_rate: 100,
                                  billing_reminder_active: true)
    @accounting_post2 = Fabricate(:accounting_post,
                                  work_item: Fabricate(:work_item, parent_id: order.work_item_id),
                                  offered_hours: 100,
                                  offered_rate: 0,
                                  billing_reminder_active: false)
  end

  test 'sends a reminder for an order responsible with active employment' do
    order_responsible = employees(:next_year_pablo)
    Fabricate(:ordertime, work_item: accounting_post1.work_item, employee: employees(:long_time_john), hours: 5, billable: true, work_date: Period.parse('-1m').end_date)

    assert_emails 1 do
      NotBilledTimesReminderJob.new.perform
    end
    mail = ActionMailer::Base.deliveries.last

    assert_equal [order_responsible.email], mail.to
  end

  test 'setting `billing_reminder_active: false` deactivates mails for an accounting_post' do
    Fabricate(:ordertime, work_item: accounting_post2.work_item, employee: employees(:long_time_john), hours: 7, billable: true, work_date: Period.parse('-1m').end_date)

    assert_emails 0 do
      NotBilledTimesReminderJob.new.perform
    end
  end
end
