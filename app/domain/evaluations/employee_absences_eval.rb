# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Evaluations
  class EmployeeAbsencesEval < Evaluations::Evaluation
    self.division_method  = :absences
    self.division_column  = :absence_id
    self.label            = 'Absenzen'
    self.absences         = true
    self.category_ref     = :employee_id
    self.detail_columns   = detail_columns.reject { |i| i == :billable }
    self.detail_labels    = detail_labels.merge(account: 'Absenz')

    def initialize(employee_id, **worktime_search_conditions)
      super(Employee.find(employee_id), **worktime_search_conditions)
    end

    def for?(user)
      category == user
    end

    def employee_id
      category.id
    end

    def account_id
      division&.id
    end
  end
end
