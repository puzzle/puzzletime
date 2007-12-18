class SubProjectsEval < ClientProjectsEval

  DIVISION_METHOD  = :children  
  LABEL            = 'Subprojekte'
  
  def initialize(project_id)
    super(Project.find(project_id))
  end   
  
end