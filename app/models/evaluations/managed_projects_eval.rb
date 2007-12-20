class ManagedProjectsEval < Evaluation

  DIVISION_METHOD   = :managed_projects
  LABEL             = 'Geleitete Projekte'
  TOTAL_DETAILS     = false  
  SUB_EVALUATION    = 'projectemployees'
  SUB_PROJECTS_EVAL = 'subprojects'
      
  def category_label
    'Kunde: ' + division.client.name
  end

  def sum_total_times(period = nil)
    category.sumManagedProjectsWorktime(period)
  end
  
  def account_id
     division.id if division
  end

end
