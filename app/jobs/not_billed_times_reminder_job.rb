# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class NotBilledTimesReminderJob < CronJob
  self.cron_expression = '0 5 10 * *'

  def perform
    responsible_employees_with_not_billed_times_last_month.each do |employee_data|
      EmployeeMailer.not_billed_times_reminder_mail(employee_data).deliver_now
    end
  end

  def responsible_employees_with_not_billed_times_last_month
    Employee.joins(:employments)
            .joins(:worktimes)
            .joins('INNER JOIN work_items ON work_items.id = worktimes.work_item_id')
            .joins('INNER JOIN accounting_posts ON accounting_posts.work_item_id = work_items.id')
            .joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)')
            .joins('INNER JOIN employees as responsibles ON responsibles.id = orders.responsible_id')
            .where(accounting_posts: { billing_reminder_active: true })
            .where(Period.parse('-1m').where_condition('worktimes.work_date'))
            .merge(Employment.active.during(Period.previous_month))
            .where(worktimes: { billable: true, invoice_id: nil })
            .select('responsibles.*, orders.id as order_id, work_items.path_names as client')
            .distinct
  end
end
