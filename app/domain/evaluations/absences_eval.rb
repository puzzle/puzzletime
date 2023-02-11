# -*- coding: utf-8 -*-

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Evaluations::AbsencesEval < Evaluations::Evaluation
  self.sub_evaluation   = 'employeeabsences'
  self.division_column  = :employee_id
  self.label            = 'Members Absenzen'
  self.absences         = true
  self.detail_columns   = detail_columns.reject { |i| i == :billable }
  self.detail_labels    = detail_labels.merge(account: 'Absenz')

  def initialize(**search_conditions)
    super(Employee, **search_conditions)
  end

  def divisions(period = nil)
    Employee.employed_ones(period || Period.current_year)
  end

  def employee_id
    division.id if division
  end

  def division_supplement(_user)
    [[:remaining_vacations, 'Übrige Ferien', 'right'],
     [:overtime_vacations_tooltip, '', 'left']]
  end
end
