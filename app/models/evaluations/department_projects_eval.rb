# encoding: utf-8

class DepartmentProjectsEval < ProjectsEval

  self.division_join     = nil

  def initialize(department_id)
    super(Department.find(department_id))
  end

end
