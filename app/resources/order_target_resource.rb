# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Read-only; written in bulk by Api::V2::OrderOperationsController. Visible like the targets of an order are
# (everybody may `show_targets`).
class OrderTargetResource < ApplicationResource
  model OrderTarget

  # Served from `/orders/:id/targets`, not from a route of its own.
  self.validate_requests = false

  attributes_writable_by_default false

  attribute :order_id, :integer
  attribute :target_scope_id, :integer
  attribute :rating, :string
  attribute :comment, :string

  def base_scope
    super.list
  end
end
