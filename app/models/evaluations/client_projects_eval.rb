class ClientProjectsEval < Evaluation

  DIVISION_METHOD   = :projects
  LABEL             = 'Projekte'   
  SUB_EVALUATION    = 'projectemployees'
  SUB_PROJECTS_EVAL = 'subprojects'
  
  def initialize(client_id)
    super(client_id.is_a?(ActiveRecord::Base) ? client_id : Client.find(client_id))
  end   
  
  def account_id
     division.id if division
  end
 
  def division_supplement(user)
     [[:offered_hours, 'Offeriert']]
  end
  
end