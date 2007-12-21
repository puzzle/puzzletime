class ManagedProjectsEval < ProjectsEval

  DIVISION_METHOD   = :managed_projects
  LABEL             = 'Geleitete Projekte'
  TOTAL_DETAILS     = false  
      
  def category_label
    'Kunde: ' + division.client.name
  end

  def sum_total_times(period = nil)
    category.sumManagedProjectsWorktime(period)
  end

end
