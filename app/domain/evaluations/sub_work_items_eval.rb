# encoding: utf-8

class SubWorkItemsEval < WorkItemsEval
  self.division_method  = :children
  self.label            = 'Subpositionen'

  def initialize(item_id)
    super(WorkItem.find(item_id))
  end

  def account_id
    division ? division.id : category.id
  end

  # Label for the represented category.
  def category_label
    'Kunde: ' + category.top_item.client.label
  end

  # Label for the represented division, if any.
  def division_label
    'Position: ' + (division ? division : category).label_ancestry
  end

  def division_column
    "work_items.path_ids[#{category.path_ids.size + 1}]"
  end
end
