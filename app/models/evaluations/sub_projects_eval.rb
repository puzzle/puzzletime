class SubProjectsEval < ProjectsEval

  DIVISION_METHOD  = :children  
  LABEL            = 'Subprojekte'
  
  def initialize(project_id)
    super(Project.find(project_id))
  end
  
  def account_id
     division ? division.id : category.id
  end
  
  # Label for the represented category.
  def category_label
    'Kunde: ' + category.client.label
  end  
  
  # Label for the represented division, if any.
  def division_label
    'Projekt: ' + (division ? division : category).label_ancestry
  end
end