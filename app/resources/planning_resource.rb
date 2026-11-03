# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Read-only (no write routes: the model lacks the validations Plannings::Creator relies on). Management sees all,
# others their own rows plus rows below orders they are responsible for.
class PlanningResource < ApplicationResource
  model Planning

  attribute :employee_id, :integer
  attribute :work_item_id, :integer
  attribute :date, :date
  attribute :percent, :integer
  attribute :definitive, :boolean

  def base_scope
    return Planning.all if management?
    return Planning.none unless current_user.is_a?(Employee)

    Planning.where(employee_id: current_user.id).or(Planning.where(<<~SQL.squish, current_user.id))
      EXISTS (SELECT 1 FROM work_items wi JOIN orders o ON o.work_item_id = ANY (wi.path_ids)
              WHERE wi.id = plannings.work_item_id AND o.responsible_id = ?)
    SQL
  end
end
