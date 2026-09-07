# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Evaluations
  class AbsencesEval < Evaluations::Evaluation
    include EvaluatorHelper
    include FormatHelper
    include Sortable

    self.sub_evaluation   = 'employeeabsences'
    self.division_column  = :employee_id
    self.label            = 'Members Absenzen'
    self.absences         = true
    self.detail_columns   = detail_columns.reject { |i| i == :billable }
    self.detail_labels    = detail_labels.merge(account: 'Absenz')
    self.sortable_division_header = true
    self.sortable_period_header   = true

    attr_reader :department_id, :sort_conditions

    def initialize(department_id = nil, sort_conditions = nil, **worktime_search_conditions)
      super(Employee, **worktime_search_conditions)
      @department_id = department_id
      @sort_conditions = sort_conditions
    end

    def divisions(period = nil, times = nil)
      employees = employees_with_absences(period, times).map do |e|
        e.remaining_vacations = format_days(vacations_value(e))
        e
      end
      sort_divisions(employees, times)
    end

    def employees_with_absences(period, times)
      scope = Employee.employed_ones(period || Period.current_year)

      scope = scope.where(department_id: department_id) if department_id.present?
      scope.filter do |e|
        times_or_plannings?(self, e, times, [period])
      end
    end

    # Absences must additionally be filtered by department id (overwrite)
    def sum_total_times(period = nil)
      query = worktime_query(category, period)
      query = query.joins(:employee).where(employees: { department_id: department_id }) if department_id.present?
      query_time_sums(query)
    end

    def division_header
      'Member'
    end

    def employee_id
      division&.id
    end

    def division_supplement(_user)
      {
        remaining_vacations: { title: 'Übrige Ferien', align: 'right', sortable: true },
        overtime_vacations_tooltip: {}
      }
    end

    private

    def sort_divisions(employees, times)
      case sort_conditions && sort_conditions['sort']
      when 'name' then sort_by_name(employees)
      when 'period_hours' then sort_by_value(employees) { |e| period_hours_value(e, times) }
      else sort_by_value(employees) { |e| vacations_value(e) }
      end
    end

    def sort_by_name(employees)
      sorted = employees.sort_by { |e| [e.lastname, e.firstname] }
      sort_direction == :desc ? sorted.reverse : sorted
    end

    def sort_by_value(employees)
      employees.sort_by { |e| yield(e) * sort_multiplier }
    end

    def vacations_value(employee)
      remaining_vacations(employee, format: false)
    end
  end
end
