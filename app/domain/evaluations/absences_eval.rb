# encoding: utf-8

class AbsencesEval < Evaluation
  self.sub_evaluation   = 'employeeabsences'
  self.division_column  = :employee_id
  self.label            = 'Mitarbeiter Absenzen'
  self.absences         = true
  self.total_details    = false
  self.detail_columns   = detail_columns.reject { |i| :billable == i }
  self.detail_labels    = detail_labels.merge(account: 'Absenz')

  def initialize
    super(Employee)
  end

  def divisions(period = nil)
    Employee.employed_ones(period || Period.current_year)
  end

  def employee_id
    division.id if division
  end

  def division_supplement(_user)
    [[:remaining_vacations, 'Übrige Ferien', 'right'],
     [:overtime_vacations_tooltip, '', 'left']]
 end
end
