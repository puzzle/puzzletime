# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Evaluations
  class EmployeesEval < Evaluations::Evaluation
    include Sortable

    self.division_column = 'employee_id'
    self.sub_evaluation   = 'employeeworkitems'
    self.label            = 'Member Zeit'
    self.total_details    = false
    self.sortable_division_header = true
    self.sortable_period_header   = true

    attr_reader :sort_conditions

    def initialize(emp_search_conditions = {}, sort_conditions = nil)
      @department_id = emp_search_conditions[:department_id].to_i
      @member_coach_id = emp_search_conditions[:member_coach_id].to_i
      @sort_conditions = sort_conditions
      super(Employee)
    end

    def divisions(period = nil, times = nil)
      employees = if period
                    Employee.list
                  else
                    Employee.employed_ones(Period.current_year)
                  end
      employees = employees.where(member_coach_id: @member_coach_id) unless @member_coach_id.zero?
      employees = employees.where(department_id: @department_id) unless @department_id.zero?

      sort_divisions(employees, period, times)
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
      {
        overtime: { title: 'Überstunden', align: 'right', sortable: true },
        vacations: { title: 'Ferien', align: 'right', sortable: true },
        overtime_vacations_tooltip: {},
        worktime_commits: { title: 'Freigabe', sortable: true },
        worktime_reviews: { title: 'Kontrolle', sortable: true }
      }
    end

    private

    def sort_divisions(employees, period, times)
      case sort_conditions && sort_conditions['sort']
      when 'name' then employees.reorder(lastname: sort_direction, firstname: sort_direction)
      when 'worktime_commits' then employees.reorder(committed_worktimes_at: sort_direction)
      when 'worktime_reviews' then employees.reorder(reviewed_worktimes_at: sort_direction)
      when 'overtime' then sort_by_value(employees) { |e| overtime_value(e, period) }
      when 'vacations' then sort_by_value(employees) { |e| vacations_value(e, period) }
      when 'period_hours' then sort_by_value(employees) { |e| period_hours_value(e, times) }
      else employees
      end
    end

    # Built as a fresh relation rather than chained onto `employees`, since the latter may
    # carry a `distinct` and Postgres rejects an in_order_of ORDER BY on that.
    def sort_by_value(employees)
      ranked_ids = employees.sort_by { |e| yield(e) * sort_multiplier }.map(&:id)
      Employee.where(id: ranked_ids).in_order_of(:id, ranked_ids)
    end

    def overtime_value(employee, period)
      period ? employee.statistics.overtime(period) : employee.statistics.current_overtime
    end

    def vacations_value(employee, period)
      date = period&.end_date || Time.zone.today
      employee.statistics.remaining_vacations(date.end_of_year)
    end
  end
end
