# encoding: utf-8

class ClientProjectsEval < ProjectsEval

  def initialize(client_id)
    super(Client.find(client_id))
  end

end
