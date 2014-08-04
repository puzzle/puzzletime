# encoding: utf-8

class ClientsEval < Evaluation

  self.division_column   = 'work_items.path_ids[1]'
  self.division_join     = :work_item
  self.sub_evaluation   = 'clientworkitems'
  self.label            = 'Kunden'
  self.total_details    = false

  def initialize
    super(Client)
  end

  def divisions(period = nil)
    WorkItem.joins(:client).list
  end

end
