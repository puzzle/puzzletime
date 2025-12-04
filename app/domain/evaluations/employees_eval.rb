# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Evaluations
  class EmployeesEval < Evaluations::Evaluation
    self.division_column = 'employee_id'
    self.sub_evaluation   = 'employeeworkitems'
    self.label            = 'Member Zeit'
    self.total_details    = false

    def initialize(emp_search_conditions = {})
      @department_id = emp_search_conditions[:department_id].to_i
      @member_coach_id = emp_search_conditions[:member_coach_id].to_i
      super(Employee)
    end

    def divisions(period = nil)
      employees = if period
                    Employee.list
                  else
                    Employee.employed_ones(Period.current_year)
                  end
      employees = employees.where(member_coach_id: @member_coach_id) unless @member_coach_id.zero?
      employees = employees.where(department_id: @department_id) unless @department_id.zero?

      employees
    end

    def employee_id
      division&.id
    end

    def sum_total_times(period = nil)
      query = if @department_id.zero? && @member_coach_id.zero?
                Worktime.all
              elsif @member_coach_id.zero?
                Department.find(@department_id).employee_worktimes
              elsif @department_id.zero?
                Worktime.joins(:employee)
                        .where(employees: { member_coach_id: @member_coach_id })
              else
                Worktime.joins(:employee)
                        .where(employees: { department_id: @department_id, member_coach_id: @member_coach_id })
              end
      query = query.where(type: worktime_type).in_period(period)
      query_time_sums(query)
    end

    def division_supplement(_user)
      [[:overtime, 'Überstunden', 'right'],
       [:overtime_vacations_tooltip, '', 'left'],
       [:worktime_commits, 'Freigabe', 'left'],
       [:worktime_reviews, 'Kontrolle', 'left']]
    end
  end
end
