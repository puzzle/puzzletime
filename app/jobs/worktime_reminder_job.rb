#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class CommitReminderJob < CronJob
  self.cron_expression = '45 16 * * *'

  def perform
    Employee.active_employed_last_month.where(worktimes_reminder: true).each do |employee|
      EmployeeMailer.worktime_reminder_mail(employee).deliver_now
    end
  end
end
