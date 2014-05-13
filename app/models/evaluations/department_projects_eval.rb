class DepartmentProjectsEval < ProjectsEval

  def initialize(department_id)
    super(Department.find(department_id))
  end

end
