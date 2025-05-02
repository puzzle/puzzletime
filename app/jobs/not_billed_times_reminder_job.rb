# frozen_string_literal: true

#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class NotBilledTimesReminderJob < CronJob
  self.cron_expression = '0 5 10 * *'

  def perform
    Employee.active_employed_last_month.each do |employee|
      accounting_posts = employee.managed_orders
                                 .collect(&:accounting_posts)
                                 .flatten
                                 .filter { |ap| ap.billing_reminder_active == true }
      EmployeeMailer.not_billed_times_reminder_mail(employee).deliver_now if accounting_posts.any?(&:unbilled_billable_times_exist_in_past_month?)
    end
  end
end
