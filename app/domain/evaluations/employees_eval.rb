# encoding: utf-8

class EmployeesEval < Evaluation
  self.division_column = 'employee_id'
  self.sub_evaluation   = 'employeeworkitems'
  self.label            = 'Mitarbeiter Zeit'
  self.total_details    = false

  def initialize
    super(Employee)
  end

  def divisions(period = nil)
    period ? Employee.list : Employee.employed_ones(Period.current_year)
  end

  def employee_id
    division.id if division
  end

  def division_supplement(_user, _period = nil)
    [[:overtime, 'Überzeit', 'right'],
     [:overtime_vacations_tooltip, '', 'left'],
     [:worktime_commits, 'Freigabe', 'left']]
  end
end
