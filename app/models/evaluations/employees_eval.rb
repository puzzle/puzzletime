# encoding: utf-8

class EmployeesEval < Evaluation

  self.sub_evaluation   = 'employeeprojects'
  self.label            = 'Mitarbeiter Projektzeit'
  self.total_details    = false
  self.attendance       = true

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

  def overview_supplement(user)
    user.management ? [[:export_capacity_csv, 'Auslastung CSV'],
                       [:export_extended_capacity_csv, 'Detaillierte Auslastung CSV'],
                       [:export_ma_overview, 'MA Übersicht']] : super(user)
  end

end
