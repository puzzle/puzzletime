class ManagedProjectsEval < Evaluation

  DIVISION_METHOD  = :managed_projects
  SUB_EVALUATION   = 'projectemployees'
  LABEL            = 'Geleitete Projekte'
  TOTAL_DETAILS    = false  
      
  def category_label
    'Kunde: ' + division.client.name
  end

  def sum_total_times(period = nil)
    category.sumManagedProjectsWorktime(period)
  end

end
