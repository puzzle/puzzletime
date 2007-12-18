class EmployeeProjectsEval < Evaluation

  DIVISION_METHOD  = :projects
  LABEL            = 'Projekte'
  CATEGORY_REF     = :employee_id   
  ATTENDANCE       = true   
  
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
 
  def sub_evaluation(project = nil)
    project ||= division
    project.children? ? "employeesubprojects#{employee_id}" : nil
  end
  
end
