class EmployeesEval < Evaluation

  SUB_EVALUATION   = 'employeeprojects'
  LABEL            = 'Mitarbeiter Projektzeit'
  TOTAL_DETAILS    = false
  ATTENDANCE       = true
  
  def initialize
    super(Employee)
  end  
  
  def divisions(period = nil)  
    Employee.employed_ones(period || Period.currentYear)
  end
  
  def employee_id
     division.id if division
  end
 
  def division_supplement(user)
     [[:overtime, 'Überzeit', 'right'],
      [:overtime_vacations_tooltip, '', 'left']]
  end

  def overview_supplement(user)
    user.management ? [[:exportCapacityCSV, 'MA Auslastung CSV']] : super(user)
  end
 
end