# encoding: utf-8

class AbsencesEval < Evaluation

  SUB_EVALUATION   = 'employeeabsences'
  LABEL            = 'Mitarbeiter Absenzen'
  ABSENCES         = true
  TOTAL_DETAILS    = false
  DETAIL_COLUMNS   = superclass::DETAIL_COLUMNS.reject { |i| :billable == i || :booked == i }
  DETAIL_LABELS    = superclass::DETAIL_LABELS.merge(account: 'Absenz')

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
    [[:remaining_vacations, 'Übrige Ferien', 'right'],
     [:overtime_vacations_tooltip, '', 'left']]
 end

end
