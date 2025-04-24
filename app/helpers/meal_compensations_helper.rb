# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module MealCompensationsHelper
  def meal_compensation_positions(worktimes)
    worktimes.each_with_object({}) do |worktime, positions|
      positions[worktime.account] ||= 0
      positions[worktime.account] += worktime.hours
    end
  end

  # returns a 2d hash where at index [employee_id, date] the value is true if and only if this day is eligible for meal_compensation
  def employee_id_meal_compensations_days(worktimes)
    compacted_worktime(worktimes).transform_keys(&:id).transform_values do |workdates|
      workdates.values.sum { |h| h >= 4 ? 1 : 0 }
    end
  end

  def meal_compensations_total(worktimes)
    compacted_worktime(worktimes).values.flat_map do |workdates|
      workdates.values.map { |h| h >= 4 ? 1 : 0 }
    end
    .sum
  end

  def employee_meal_compensations(worktimes)
    compacted_worktime(worktimes).map do |employee, workdates|
      numb_of_days = workdates.values.sum { |h| h >= 4 ? 1 : 0 }
      next if numb_of_days.zero?

      yield(employee, numb_of_days)
    end
  end

  def employee_meal_compensation_days(employee, period)
    worktimes = employee.worktimes.in_period(period).where(meal_compensation: true)
    workdates = worktimes.each_with_object({}) do |worktime, dates|
      dates[worktime.work_date] ||= 0.0
      dates[worktime.work_date] += worktime.hours
      dates
    end
    workdates.values.sum { |h| h >= 4 ? 1 : 0 }
  end

  def commited_state_cell(employee, period)
    icon = completion_state_icon(employee.committed_period?(period))
    date = format_month(employee.committed_worktimes_at)
    id = "committed_worktimes_at_#{employee.id}"

    content_tag(:span, icon << ' ' << date, id:)
  end

  def reviewed_state_cell(employee, period)
    icon = completion_state_icon(employee.reviewed_period?(period))
    date = format_month(employee.reviewed_worktimes_at)
    id = "reviewed_worktimes_at_#{employee.id}"

    content_tag(:span, icon << ' ' << date, id:)
  end

  def completion_state_icon(state)
    if state
      picon('disk', class: 'green')
    else
      picon('square', class: 'red')
    end
  end

  private

  def compacted_worktime(worktimes)
    worktimes.each_with_object({}) do |worktime, employees|
      employees[worktime.employee] ||= {}
      employees[worktime.employee][worktime.work_date] ||= 0.0
      employees[worktime.employee][worktime.work_date] += worktime.hours
      employees
    end
  end
end
