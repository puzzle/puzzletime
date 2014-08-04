# encoding: utf-8

# TODO: rewrite to DepartmentOrdersEval or remove
class DepartmentWorkItemsEval < WorkItemsEval

  self.division_join     = nil

  def initialize(department_id)
    super(Department.find(department_id))
  end

end
