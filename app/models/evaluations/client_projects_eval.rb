class ClientProjectsEval < Evaluation

  DIVISION_METHOD  = :projects
  SUB_EVALUATION   = 'projectemployees'
  LABEL            = 'Projekte'
  
  def initialize(client_id)
    super(Client.find(client_id))
  end   
  
end