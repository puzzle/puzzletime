class ClientProjectsEval < Evaluation

  DIVISION_METHOD  = :projects
  SUB_EVALUATION   = 'projectemployees'
  LABEL            = 'Projekte'   
  
  def initialize(client_id)
    super(Client.find(client_id))
  end   
  
  def account_id
     division.id if division
  end
  
end