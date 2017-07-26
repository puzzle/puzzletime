# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class BaseCapacityReport
  def initialize(period, filename_prefix)
    @period = period
    @filename_prefix = filename_prefix
  end

  def filename
    "#{@filename_prefix}_#{format_date(@period.start_date)}_#{format_date(@period.end_date)}.csv"
  end

  def find_billable_time(employee, work_item_id, period)
    Worktime.find_by_sql [''"SELECT SUM(w.hours) AS HOURS, w.billable FROM worktimes w
                             LEFT JOIN work_items p ON p.id = w.work_item_id
                             WHERE w.employee_id = ? AND ? = ANY(p.path_ids)
                             AND w.work_date BETWEEN ? AND ?
                             GROUP BY w.billable"'',
                          employee.id, work_item_id, period.start_date, period.end_date]
  end

  def extract_billable_hours(result, billable)
    entry = result.find { |w| w.billable == billable }
    entry ? entry.hours : 0
  end

  def employee_absences(employee, period)
    employee.worktimes.includes(:absence).
      in_period(period).
      where(type: 'Absencetime', absences: { payed: true }).
      sum(:hours).
      to_f
  end

  private

  def format_date(date)
    I18n.l(date, format: '%Y%m%d')
  end
end
