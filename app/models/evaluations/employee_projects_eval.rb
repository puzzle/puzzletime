class EmployeeProjectsEval < Evaluation

  DIVISION_METHOD  = :projects
  LABEL            = 'Projekte'
  CATEGORY_REF     = :employee_id      
  
  def initialize(employee_id)
    super(Employee.find(employee_id))
  end  
  
  def for?(user)
    self.category == user
  end
  
  def division_supplement(user)
    return [:add_time_link, :complete_link] if self.for? user
    super(user)
  end
end
