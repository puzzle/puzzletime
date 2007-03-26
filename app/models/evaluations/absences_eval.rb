class AbsencesEval < Evaluation

  SUB_EVALUATION   = 'employeeabsences'
  LABEL            = 'Mitarbeiter Absenzen'
  ABSENCES         = true
  TOTAL_DETAILS  = false
  
  def initialize
    super(Employee)
  end 
      
end