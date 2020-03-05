#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class SubWorkItemsEval < WorkItemsEval
  self.division_method   = :children
  self.label             = 'Subpositionen'
  self.billable_hours    = true
  self.planned_hours     = true

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
