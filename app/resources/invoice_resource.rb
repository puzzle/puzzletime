# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Read-only (no write routes: invoices sync with the remote Invoicing system, see InvoicesController). Invoices
# carry amounts: management sees all, order responsibles those of their orders.
class InvoiceResource < ApplicationResource
  model Invoice

  attribute :order_id, :integer
  attribute :billing_address_id, :integer
  attribute :billing_date, :date
  attribute :due_date, :date
  attribute :period_from, :date
  attribute :period_to, :date
  attribute :status, :string
  attribute :grouping, :string
  attribute :reference, :string
  attribute :total_amount, :big_decimal
  attribute :total_hours, :float

  def base_scope
    return Invoice.all if management?
    return Invoice.none unless current_user.is_a?(Employee)

    Invoice.where(order_id: Order.where(responsible_id: current_user.id).select(:id))
  end
end
