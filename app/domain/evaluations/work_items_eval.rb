# encoding: utf-8

# abstract class for evaluation with work item divisions
class WorkItemsEval < Evaluation

  self.division_method   = :work_items
  self.division_column   = 'work_items.path_ids[1]'
  self.division_join     = :work_item
  self.label             = 'Positionen'
  self.sub_evaluation    = 'workitememployees'
  self.sub_work_items_eval = 'subworkitems'

  def account_id
    division.id if division
  end

end
