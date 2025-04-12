# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Evaluations
  class WorkItemEmployeesEval < Evaluations::Evaluation
    self.division_method  = :employees
    self.division_column  = :employee_id
    self.label            = 'Members'
    self.category_ref     = 'ANY ( path_ids )'
    self.billable_hours    = true
    self.planned_hours     = true

    def initialize(item_id)
      super(WorkItem.find(item_id))
    end

    def employee_id
      division&.id
    end

    def account_id
      category.id
    end

    ####### overwritten methods for working with work item hierarchies

    def category_label
      "Position: #{category.top? ? category.label : category.label_verbose}"
    end

    def worktime_query(receiver, period = nil, division = nil)
      super.joins(:work_item)
    end

    def set_division_id(division_id = nil)
      return if division_id.nil?

      @division = Employee.find(division_id.to_i)
    end

    def division_supplement(_user)
      [
        [:worktime_commits_readonly, 'Freigabe', 'left'],
        [:worktime_reviews_readonly, 'Kontrolle', 'left']
      ]
    end
  end
end
