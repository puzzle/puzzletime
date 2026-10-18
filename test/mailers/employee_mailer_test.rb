# frozen_string_literal: true

require 'test_helper'

class EmployeeMailerTest < ActionMailer::TestCase
  attr_reader :order, :reminded_post, :unreminded_post

  setup do
    @order = Fabricate(:order,
                       responsible: employees(:next_year_pablo))
    @reminded_post = Fabricate(:accounting_post,
                               work_item: Fabricate(:work_item, parent_id: order.work_item_id),
                               offered_hours: 100,
                               offered_rate: 100,
                               billing_reminder_active: true)
    @unreminded_post = Fabricate(:accounting_post,
                                 work_item: Fabricate(:work_item, parent_id: order.work_item_id),
                                 offered_hours: 100,
                                 offered_rate: 0,
                                 billing_reminder_active: false)
  end

  test 'sends a reminder for an order responsible with active employment' do
    order_responsible = employees(:next_year_pablo)
    Fabricate(:ordertime, work_item: reminded_post.work_item, employee: employees(:long_time_john), hours: 5, billable: true, work_date: Period.parse('-1m').end_date)

    emails = capture_emails do
      NotBilledTimesReminderJob.new.perform
    end

    assert_equal 1, emails.count
    mail = emails.first
    body = mail.text_part.body.raw_source.gsub(/\s+/, ' ')
    client = reminded_post.path_names.gsub(/\s+/, ' ')

    assert_equal [order_responsible.email], mail.to
    assert_equal "PTime: #{reminded_post.path_names} - nicht verrechnete Leistungen im letzten Monat gefunden", mail.subject

    assert_match(/Hallo #{order_responsible.firstname}/, body)

    assert_match(/Beim Auftrag #{client} wurden im letzten Monat verrechenbare Leistungen gebucht, welche noch keiner Rechnung zugeteilt wurden./, body)
    assert_match(%r{orders/#{order.id}/order_services\?invoice_id=%5Bleer%5D}, body)
    assert_match(/Möchtest du zu einer Buchungsposition künftig keine Erinnerungsmail mehr erhalten, deaktiviere in den Einstellungen der Position die Checkbox "Erinnerung bei unverrechneten Leistungen senden"/, body)
    assert_match(/Liebe Grüsse Dein PuzzleTime/, body)
  end

  test 'setting `billing_reminder_active: false` deactivates mails for an accounting_post' do
    Fabricate(:ordertime, work_item: unreminded_post.work_item, employee: employees(:long_time_john), hours: 7, billable: true, work_date: Period.parse('-1m').end_date)

    assert_emails 0 do
      NotBilledTimesReminderJob.new.perform
    end
  end
end
