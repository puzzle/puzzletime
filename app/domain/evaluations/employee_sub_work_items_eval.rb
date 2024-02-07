# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Evaluations
  class EmployeeSubWorkItemsEval < Evaluations::SubWorkItemsEval
    include Conditioner

    self.sub_work_items_eval = 'employeesubworkitems'
    self.sub_evaluation    = nil
    self.detail_columns    = detail_columns.collect { |i| i == :hours ? :times : i }
    self.billable_hours    = false
    self.planned_hours     = false

    attr_reader :employee_id

    def initialize(work_item_id, employee_id)
      super(work_item_id)
      @employee_id = employee_id
    end

    def for?(user)
      employee_id == user.id
    end

    def worktime_query(receiver, period = nil, division = nil)
      super(receiver, period, division).where(employee_id:)
    end

    def sub_work_items_evaluation(division = nil)
      sub_work_items_eval + employee_id.to_s if division.children?
    end
  end
end
