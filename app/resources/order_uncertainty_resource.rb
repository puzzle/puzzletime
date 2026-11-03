# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Read-only base of risks and chances (single table inheritance): everybody reads all of them.
class OrderUncertaintyResource < ApplicationResource
  include AbilityScoped

  model OrderUncertainty

  attributes_writable_by_default false

  attribute :order_id, :integer
  attribute :type, :string
  attribute :name, :string
  attribute :probability, :string_enum, allow: OrderUncertainty.probabilities.keys
  attribute :impact, :string_enum, allow: OrderUncertainty.impacts.keys
  attribute :measure, :string

  belongs_to :order

  def base_scope
    super.list
  end
end
