# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class NotBilledTimesReminderJob < CronJob
  self.cron_expression = '0 5 10 * *'

  def perform
    Employee.responsibles_with_not_billed_times_last_month.each do |employee_data|
      EmployeeMailer.not_billed_times_reminder_mail(employee_data).deliver_now
    end
  end
end
