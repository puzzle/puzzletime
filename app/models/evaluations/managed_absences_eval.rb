class ManagedAbsencesEval < Evaluation

  DIVISION_METHOD  = :managed_employees
  SUB_EVALUATION   = 'employeeabsences'
  LABEL            = 'Geleitete Projekte'
  TOTAL_DETAILS    = false
  
  def category_label
    'Kunde: ' + division.client.name
  end
  
  def account_id
     division.id if division
  end
  
end