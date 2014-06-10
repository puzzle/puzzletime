# encoding: utf-8

class EmployeeProjectsEval < ProjectsEval

  self.category_ref      = :employee_id
  self.attendance        = true
  self.sub_evaluation    = nil
  self.sub_projects_eval = 'employeesubprojects'
  self.detail_columns    = detail_columns.collect { |i| i == :hours ? :times : i }


  # alltime: boolean, use all projects ever worked for / only current memberships
  def initialize(employee_id, alltime)
    super(Employee.find(employee_id))
    @alltime = alltime
  end

  def divisions(period = nil)
    @alltime ? category.alltime_projects.includes(:client) : category.projects.includes(:client)
  end

  def for?(user)
    category == user
  end

  def division_supplement(user)
    return [[:add_time_link, ''], [:complete_link, '']] if self.for? user
    []
  end

  def employee_id
    category.id
  end

  def sub_projects_evaluation(project = nil)
    sub_projects_eval + employee_id.to_s if project && project.children?
  end

  # default would turn Employee.alltime_projects too complicated
  def set_division_id(division_id = nil)
    return if division_id.nil?
    @division = Project.find(division_id.to_i)
  end
end
