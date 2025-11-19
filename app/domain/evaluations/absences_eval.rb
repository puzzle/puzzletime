# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Evaluations
  class AbsencesEval < Evaluations::Evaluation
    include EvaluatorHelper
    include FormatHelper

    self.sub_evaluation   = 'employeeabsences'
    self.division_column  = :employee_id
    self.label            = 'Members Absenzen'
    self.absences         = true
    self.detail_columns   = detail_columns.reject { |i| i == :billable }
    self.detail_labels    = detail_labels.merge(account: 'Absenz')

    attr_reader :department_id, :sort_conditions

    def initialize(department_id = nil, sort_conditions = nil, **worktime_search_conditions)
      super(Employee, **worktime_search_conditions)
      @department_id = department_id
      @sort_conditions = sort_conditions
    end

    def divisions(period = nil, times = nil)
      employees_with_absences(period, times).map do |e|
        unformatted_vacations = remaining_vacations(e, format: false)
        e.remaining_vacations = format_days(unformatted_vacations)
        e.sort_col = unformatted_vacations * descending
        e
      end.sort_by(&:sort_col)
    end

    def employees_with_absences(period, times)
      scope = Employee.employed_ones(period || Period.current_year)

      scope = scope.where(department_id: department_id) if department_id.present?
      scope.filter do |e|
        times_or_plannings?(self, e, times, [period])
      end
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

    def descending
      sort_conditions && sort_conditions['sort_dir'] == 'desc' ? -1 : 1
    end
  end
end
