# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class EmployeeWorkItemsEval < WorkItemsEval
  self.category_ref      = :employee_id
  self.sub_evaluation    = nil
  self.division_method   = :alltime_main_work_items
  self.sub_work_items_eval = 'employeesubworkitems'
  self.detail_columns = detail_columns.collect { |i| i == :hours ? :times : i }


  def initialize(employee_id)
    super(Employee.find(employee_id))
  end

  def for?(user)
    category == user
  end

  def division_supplement(_user)
    []
  end

  def employee_id
    category.id
  end

  def sub_work_items_evaluation(work_item = nil)
    sub_work_items_eval + employee_id.to_s if work_item && work_item.children?
  end

  def set_division_id(division_id = nil)
    return if division_id.nil?
    @division = WorkItem.find(division_id.to_i)
  end
end
