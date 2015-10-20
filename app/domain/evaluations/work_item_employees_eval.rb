# encoding: utf-8

class WorkItemEmployeesEval < Evaluation
  self.division_method  = :employees
  self.division_column  = :employee_id
  self.label            = 'Mitarbeiter'
  self.category_ref     = 'ANY ( path_ids )'

  def initialize(item_id)
    super(WorkItem.find(item_id))
  end

  def employee_id
    division.id if division
  end

  def account_id
    category.id
  end

  ####### overwritten methods for working with work item hierarchies

  def category_label
    "Position: #{category.top? ? category.label : category.label_verbose}"
  end

  def worktime_query(receiver, period = nil, division = nil)
    super(receiver, period, division).joins(:work_item)
  end

  def set_division_id(division_id = nil)
    return if division_id.nil?
    @division = Employee.find(division_id.to_i)
  end
end
