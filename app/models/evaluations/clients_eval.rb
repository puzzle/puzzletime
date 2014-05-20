# encoding: utf-8

class ClientsEval < Evaluation

  self.sub_evaluation   = 'clientprojects'
  self.label            = 'Kunden'
  self.total_details    = false

  def initialize
    super(Client)
  end

end
