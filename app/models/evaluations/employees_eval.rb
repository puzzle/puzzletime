# encoding: utf-8

class EmployeesEval < Evaluation

  self.division_column   = 'employee_id'
  self.sub_evaluation   = 'employeeprojects'
  self.label            = 'Mitarbeiter Projektzeit'
  self.total_details    = false

  def initialize
    super(Employee)
  end

  def divisions(period = nil)
    Employee.employed_ones(period || Period.current_year)
  end

  def employee_id
    division.id if division
  end

  def division_supplement(user)
    [[:overtime, 'Überzeit', 'right'],
     [:overtime_vacations_tooltip, '', 'left']]
  end

end
