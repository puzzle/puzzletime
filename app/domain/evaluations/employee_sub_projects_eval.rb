# encoding: utf-8

class EmployeeSubProjectsEval < SubProjectsEval

  include Conditioner

  self.sub_projects_eval = 'employeesubprojects'
  self.sub_evaluation    = nil
  self.detail_columns    = detail_columns.collect { |i| i == :hours ? :times : i }

  attr_reader :employee_id

  def initialize(project_id, employee_id)
    super(project_id)
    @employee_id = employee_id
  end

  def for?(user)
    employee_id == user.id
  end

  def worktime_query(receiver, period = nil, division = nil)
    super(receiver, period, division).where(employee_id: employee_id)
  end

  def sub_projects_evaluation(division = nil)
    sub_projects_eval + employee_id.to_s if division.sub_projects?
  end

end
