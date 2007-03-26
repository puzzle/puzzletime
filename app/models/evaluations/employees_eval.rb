class EmployeesEval < Evaluation

  SUB_EVALUATION   = 'employeeprojects'
  LABEL           = 'Mitarbeiter Projekt'
  TOTAL_DETAILS  = false
  
  def initialize
    super(Employee)
  end  
  
end