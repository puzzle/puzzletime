#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module MealCompensationsHelper
  def employee_meal_compensations(worktimes, period)
    compacted_worktime(worktimes).map do |employee, workdates|
      numb_of_days = workdates.values.sum(0) { |h| h >= 4 ? 1 : 0 }
      next if numb_of_days == 0

      [
        employee.to_s,
        numb_of_days,
        completion_state_icon(employee.committed_period?(period)),
        completion_state_icon(employee.reviewed_period?(period))
      ]
    end.compact
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
