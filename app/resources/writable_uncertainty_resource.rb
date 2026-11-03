# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Writing risks and chances (OrderUncertaintiesController): Ability asks for the order's responsible; the order of
# an uncertainty is fixed on creation. Saving re-saves the order (its major value), so an invalid order has to fail
# the request instead of being swallowed by ActiveRecord.
class WritableUncertaintyResource < OrderUncertaintyResource
  self.abstract_class = true

  attribute :order_id, :integer, writable: :creating?
  attribute :name, :string, writable: true
  attribute :probability, :string_enum, allow: OrderUncertainty.probabilities.keys, writable: true
  attribute :impact, :string_enum, allow: OrderUncertainty.impacts.keys, writable: true
  attribute :measure, :string, writable: true

  # Writable guard: the order of an uncertainty is fixed on creation.
  def creating?
    guard_model.new_record?
  end

  def save(model, meta = nil)
    model.order&.tap do |order|
      order.valid? || order.errors.each { |error| model.errors.add(:"order.#{error.attribute}", error.message) }
    end
    model.errors.any? ? model : super
  end
end
