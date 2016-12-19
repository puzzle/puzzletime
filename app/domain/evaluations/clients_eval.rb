# encoding: utf-8

class ClientsEval < Evaluation
  self.division_column   = 'work_items.path_ids[1]'
  self.division_join     = :work_item
  self.sub_evaluation   = 'clientworkitems'
  self.label            = 'Kunden'
  self.total_details    = false
  self.billable_hours    = true
  self.planned_hours     = true

  def initialize
    super(Client)
  end

  def divisions(_period = nil)
    WorkItem.joins(:client).list
  end

  def set_division_id(division_id = nil)
    return if division_id.nil?
    @division = WorkItem.find(division_id.to_i)
  end
end
