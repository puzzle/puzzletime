class EmployeesEval < Evaluation

  SUB_EVALUATION   = 'employeeprojects'
  LABEL            = 'Mitarbeiter Projektzeit'
  TOTAL_DETAILS    = false
  ATTENDANCE       = true
  
  def initialize
    super(Employee)
  end  
  
end