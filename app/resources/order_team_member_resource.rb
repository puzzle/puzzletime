# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Written only as a sidepost of an order (no endpoint of its own).
class OrderTeamMemberResource < ApplicationResource
  include AuthorizedThroughOrder

  model OrderTeamMember

  attribute :order_id, :integer, writable: false
  attribute :employee_id, :integer
  attribute :comment, :string

  def base_scope
    super.list
  end
end
