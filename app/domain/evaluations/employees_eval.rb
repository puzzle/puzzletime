# encoding: utf-8

class EmployeesEval < Evaluation
  self.division_column = 'employee_id'
  self.sub_evaluation   = 'employeeworkitems'
  self.label            = 'Mitarbeiter Zeit'
  self.total_details    = false

  def initialize(department_id = 0)
    @department_id = department_id.to_i
    super(Employee)
  end

  def divisions(period = nil)
    employees = if period
                  Employee.list
                else
                  Employee.employed_ones(Period.current_year)
                end

    if @department_id != 0
      employees.where(department_id: @department_id)
    else
      employees
    end
  end

  def employee_id
    division.id if division
  end

  def division_supplement(_user)
    [[:overtime, 'Überstunden', 'right'],
     [:overtime_vacations_tooltip, '', 'left'],
     [:worktime_commits, 'Freigabe', 'left'],
     [:worktime_reviews, 'Kontrolle', 'left']]
  end
end
