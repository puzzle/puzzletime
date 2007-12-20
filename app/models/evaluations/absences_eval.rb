class AbsencesEval < Evaluation

  SUB_EVALUATION   = 'employeeabsences'
  LABEL            = 'Mitarbeiter Absenzen'
  ABSENCES         = true
  TOTAL_DETAILS    = false
  DETAIL_COLUMNS   = superclass::DETAIL_COLUMNS.reject{|i| :billable == i || :booked == i }
  DETAIL_LABELS    = superclass::DETAIL_LABELS.merge({:account => 'Absenz'})
    
  def initialize
    super(Employee)
  end 
  
  def employee_id
    division.id if division
  end
      
  def division_supplement(user)
     [[:remaining_vacations, 'Übrige Ferien', 'right']]
 end
 
end