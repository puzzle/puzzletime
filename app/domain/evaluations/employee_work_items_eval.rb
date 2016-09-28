# encoding: utf-8

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

  def division_supplement(_user, _period = nil)
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
