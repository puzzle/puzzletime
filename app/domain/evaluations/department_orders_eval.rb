# encoding: utf-8

class DepartmentOrdersEval < WorkItemsEval

  self.division_join     = nil
  self.division_column   = 'orders.work_item_id'

  def initialize(department_id)
    super(Department.find(department_id))
  end

  def divisions(period = nil)
    WorkItem.joins(:order).where(orders: { department_id: category.id }).list
  end

end
