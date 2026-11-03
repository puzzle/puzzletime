# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# The contract of an order, written through `PUT /orders/:id/contract` (Api::V2::OrderOperationsController), which
# is where the order comes from: Ability asks the order, not the contract.
class ContractResource < ApplicationResource
  model Contract

  # Served from `/orders/:id/contract`, not from a route of its own.
  self.validate_requests = false

  attribute :number, :string
  attribute :start_date, :date
  attribute :end_date, :date
  attribute :payment_period, :integer
  attribute :reference, :string
  attribute :sla, :string
  attribute :notes, :string

  config[:callbacks][:save][:before].clear

  before_save { |_model| context.current_ability.authorize!(:update_contract, context.order) }

  # A new contract belongs to the order it is put on.
  def build(model, _meta = nil)
    model.new(order: context.order)
  end
end
