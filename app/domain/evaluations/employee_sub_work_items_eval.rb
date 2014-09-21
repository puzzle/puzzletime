# encoding: utf-8

class EmployeeSubWorkItemsEval < SubWorkItemsEval

  include Conditioner

  self.sub_work_items_eval = 'employeesubworkitems'
  self.sub_evaluation    = nil
  self.detail_columns    = detail_columns.collect { |i| i == :hours ? :times : i }

  attr_reader :employee_id

  def initialize(work_item_id, employee_id)
    super(work_item_id)
    @employee_id = employee_id
  end

  def for?(user)
    employee_id == user.id
  end

  def worktime_query(receiver, period = nil, division = nil)
    super(receiver, period, division).where(employee_id: employee_id)
  end

  def sub_work_items_evaluation(division = nil)
    sub_work_items_eval + employee_id.to_s if division.children?
  end

end
