# abstract class for evaluation with project divisions
class ProjectsEval < Evaluation

  DIVISION_METHOD   = :projects
  LABEL             = 'Projekte'   
  SUB_EVALUATION    = 'projectemployees'
  SUB_PROJECTS_EVAL = 'subprojects'
  
  def divisions(period = nil)  
    super.sort
  end
  
  def account_id
     division.id if division
  end
 
  def division_supplement(user)
     [[:offered_hours, 'Offeriert']]
  end
  
end