# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Evaluations
  class AbsencesEval < Evaluations::Evaluation
    self.sub_evaluation   = 'employeeabsences'
    self.division_column  = :employee_id
    self.label            = 'Members Absenzen'
    self.absences         = true
    self.detail_columns   = detail_columns.reject { |i| i == :billable }
    self.detail_labels    = detail_labels.merge(account: 'Absenz')

    attr_reader :department_id

    def initialize(department_id = nil, **worktime_search_conditions)
      super(Employee, **worktime_search_conditions)
      @department_id = department_id
    end

    def divisions(period = nil)
      scope = Employee.employed_ones(period || Period.current_year)

      return scope if department_id.blank?

      scope.where(department_id:)
    end

    def employee_id
      division&.id
    end

    def division_supplement(_user)
      [[:remaining_vacations, 'Übrige Ferien', 'right'],
       [:overtime_vacations_tooltip, '', 'left']]
    end
  end
end
