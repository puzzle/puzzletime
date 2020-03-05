#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class DepartmentOrdersEval < WorkItemsEval
  self.division_join     = nil
  self.division_column   = 'orders.work_item_id'
  self.billable_hours    = true
  self.planned_hours     = true

  def initialize(department_id)
    super(Department.find(department_id))
  end

  def divisions(_period = nil)
    WorkItem.joins(:order).includes(:order).where(orders: { department_id: category.id }).list
  end

  def division_supplement(_user)
    [[:order_completed, 'Abschluss erledigt', 'left'],
     [:order_committed, 'Abschluss freigegeben', 'left']]
  end

  def include_no_period_zero_totals
    false
  end
end
