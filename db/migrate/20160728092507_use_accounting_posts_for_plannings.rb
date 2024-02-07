# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class UseAccountingPostsForPlannings < ActiveRecord::Migration[5.1]
  def up
    Planning.find_each do |p|
      first = p.work_item.self_and_descendants.joins(:accounting_post).list.select(:id).first
      p.update_column(:work_item_id, first.id) if first
    end
  end

  def down
    Planning.find_each do |p|
      id = p.work_item.self_and_ancestors[-2].id
      p.update_column(:work_item_id, id)
    end
  end
end
