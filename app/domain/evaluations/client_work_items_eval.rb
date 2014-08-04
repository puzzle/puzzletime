# encoding: utf-8

class ClientWorkItemsEval < SubWorkItemsEval

  def initialize(client_id)
    super(WorkItem.find(client_id))
  end

end
