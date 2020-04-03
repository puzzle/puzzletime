#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module MealCompensationsHelper
  def employee_meal_compensations(worktimes)
    compacted_worktime(worktimes).map do |employee, workdates|
      numb_of_days = workdates.values.sum(0) { |h| h >= 4 ? 1 : 0 }
      next if numb_of_days == 0

      yield(employee, numb_of_days)
    end
  end

  def commited_state_cell(employee, period)
    icon = completion_state_icon(employee.committed_period?(period))
    date = format_month(employee.committed_worktimes_at)
    id = "committed_worktimes_at_#{employee.id}"

    content_tag(:span, icon << ' ' << date, id: id)
  end

  def reviewed_state_cell(employee, period)
    icon = completion_state_icon(employee.reviewed_period?(period))
    date = format_month(employee.reviewed_worktimes_at)
    id = "reviewed_worktimes_at_#{employee.id}"

    content_tag(:span, icon << ' ' << date, id: id)
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
