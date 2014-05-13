# encoding: utf-8

class EmployeeSubProjectsEval < SubProjectsEval

  include Conditioner

  SUB_PROJECTS_EVAL = 'employeesubprojects'
  SUB_EVALUATION    = nil
  DETAIL_COLUMNS    = superclass::DETAIL_COLUMNS.collect { |i| i == :hours ? :times : i }

  attr_reader :employee_id

  def initialize(project_id, employee_id)
    super(project_id)
    @employee_id = employee_id
  end

  def for?(user)
    employee_id == user.id
  end

  def division_supplement(user)
    return [[:add_time_link, ''], [:complete_link, '']] if self.for? user
    super(user)
  end

  def sum_total_times(period = nil, options = {})
    super(period, append_employee_condition(options))
  end

  def sendTimeQuery(method, period = nil, div = nil, options = {})
    super(method, period, div, append_employee_condition(options))
  end

  def sub_projects_evaluation(division = nil)
    self.class::SUB_PROJECTS_EVAL + employee_id.to_s if division.children?
  end


  private

  def append_employee_condition(options)
    options = clone_options options
    append_conditions(options[:conditions], ['employee_id = ?', employee_id])
    options
  end

end
