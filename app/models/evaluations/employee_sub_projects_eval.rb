class EmployeeSubProjectsEval < SubProjectsEval

  include Conditioner
  
  attr_reader :employee_id

  def initialize(project_id, employee_id)
    super(project_id)
    @employee_id = employee_id
  end
  
  def for?(user)
    self.employee_id == user.id
  end
  
  def division_supplement(user)
    return [[:add_time_link, '']] if self.for? user
    super(user)
  end

  def sum_total_times(period = nil, options = {})
    super(period, append_employee_condition(options))
  end
  
  
  def sendTimeQuery(method, period = nil, div = nil, options = {})
    super(method, period, div, append_employee_condition(options))
  end
  
  
  def sub_evaluation(project = nil)
    project ||= division
    project.children? ? "employeesubprojects#{employee_id}" : nil
  end
  
private
  
  def append_employee_condition(options)
    options = clone_options options
    append_conditions(options[:conditions], ['employee_id = ?', employee_id])
    options
  end
  
end