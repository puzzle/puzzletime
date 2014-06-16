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

  def division_supplement(user)
    return [[:add_time_link, ''], [:complete_link, '']] if self.for? user
    super(user)
  end

  def sum_times_grouped(period, options = {})
    super(period, append_employee_condition(options))
  end

  def sum_total_times(period = nil, options = {})
    super(period, append_employee_condition(options))
  end

  def send_time_query(method, period = nil, div = nil, options = {})
    super(method, period, div, append_employee_condition(options))
  end

  def sub_projects_evaluation(division = nil)
    sub_projects_eval + employee_id.to_s if division.sub_projects?
  end


  private

  def append_employee_condition(options)
    options = clone_options options
    append_conditions(options[:conditions], ['employee_id = ?', employee_id])
    options
  end

end
