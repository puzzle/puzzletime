#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class DepartmentsEval < Evaluation
  self.division_column   = 'orders.department_id'
  self.division_join     = 'INNER JOIN work_items ON work_items.id = worktimes.work_item_id ' \
                           'INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)'
  self.division_planning_join = 'INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)'
  self.sub_evaluation   = 'departmentorders'
  self.label            = 'Organisationseinheiten'
  self.total_details    = false
  self.billable_hours   = true
  self.planned_hours    = true

  def initialize
    super(Department)
  end
end
