# encoding: utf-8

class ClientsEval < Evaluation

  SUB_EVALUATION   = 'clientprojects'
  LABEL            = 'Kunden'
  TOTAL_DETAILS    = false

  def initialize
    super(Client)
  end

end
