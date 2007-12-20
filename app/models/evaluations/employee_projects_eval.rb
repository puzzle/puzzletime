class EmployeeProjectsEval < Evaluation

  DIVISION_METHOD   = :projects
  LABEL             = 'Projekte'
  CATEGORY_REF      = :employee_id   
  ATTENDANCE        = true   
  SUB_PROJECTS_EVAL = 'employeesubprojects'
  
  def initialize(employee_id)
    super(Employee.find(employee_id))
  end  
  
  def for?(user)
    self.category == user
  end
  
  def division_supplement(user)
    return [[:add_time_link, ''], [:complete_link, '']] if self.for? user
    super(user)
  end
  
  def employee_id
    category.id
  end
  
  def account_id
     division.id if division
  end
  
  def sub_projects_evaluation(project = nil)
    self.class::SUB_PROJECTS_EVAL + employee_id.to_s if project && project.children?
  end

  
end
