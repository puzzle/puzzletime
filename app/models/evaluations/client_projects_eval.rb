class ClientProjectsEval < Evaluation

  DIVISION_METHOD  = :projects
  LABEL            = 'Projekte'   
  
  def initialize(client_id)
    super(client_id.is_a?(ActiveRecord::Base) ? client_id : Client.find(client_id))
  end   
  
  def account_id
     division.id if division
 end
 
  def division_supplement(user)
    [[:offered_hours, 'Offeriert']]
  end
  
  def sub_evaluation(div = nil)
    div ||= division
    div.children? ? 'subprojects' : 'projectemployees'
  end
  
end