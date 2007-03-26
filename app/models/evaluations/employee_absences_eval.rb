class EmployeeAbsencesEval < Evaluation

  DIVISION_METHOD  = :absences
  LABEL            = 'Absenzen'
  ABSENCES         = true
  
  def initialize(employee_id)
    super(Employee.find(employee_id))
  end    
    
  def for?(user)
    self.category == user
  end

  def division_supplement(user)
    return [:add_time_link] if self.for? user
    super(user)
  end
  
end
