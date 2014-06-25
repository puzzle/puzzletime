# encoding: utf-8

class EmployeeProjectsEval < ProjectsEval

  self.category_ref      = :employee_id
  self.sub_evaluation    = nil
  self.division_method   = :alltime_projects
  self.sub_projects_eval = 'employeesubprojects'
  self.detail_columns    = detail_columns.collect { |i| i == :hours ? :times : i }


  def initialize(employee_id)
    super(Employee.find(employee_id))
  end

  def for?(user)
    category == user
  end

  def division_supplement(user)
    []
  end

  def employee_id
    category.id
  end

  def sub_projects_evaluation(project = nil)
    sub_projects_eval + employee_id.to_s if project && project.sub_projects?
  end

  # default would turn Employee.alltime_projects too complicated
  def set_division_id(division_id = nil)
    return if division_id.nil?
    @division = Project.find(division_id.to_i)
  end
end
