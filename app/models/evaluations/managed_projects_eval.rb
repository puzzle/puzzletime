class ManagedProjectsEval < Evaluation

  DIVISION_METHOD  = :managed_projects
  LABEL            = 'Geleitete Projekte'
  TOTAL_DETAILS    = false  
      
  def category_label
    'Kunde: ' + division.client.name
  end

  def sum_total_times(period = nil)
    category.sumManagedProjectsWorktime(period)
  end
  
  def account_id
     division.id if division
  end

  def sub_evaluation(div = nil)
    div ||= division
    div.children? ? 'subprojects' : 'projectemployees'
  end
  
end
