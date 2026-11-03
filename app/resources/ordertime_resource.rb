# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Mirrors OrdertimesController; see WorktimeResource for the rules shared with absences.
class OrdertimeResource < WorktimeResource
  model Ordertime
  secondary_endpoint '/ordertimes/repeat', %i[repeat]

  attribute :work_item_id, :integer
  attribute :internal_description, :string
  attribute :billable, :boolean
  attribute :ticket, :string
  attribute :meal_compensation, :boolean
  attribute :invoice_id, :integer, writable: false

  def save(entry, meta = nil)
    check_accounting_post(entry)
    super
  end

  private

  def check_accounting_post(entry)
    return unless entry.work_item && !entry.work_item.accounting_post

    entry.errors.add(:work_item_id, 'Der Auftrag hat keine Buchungsposition.')
  end

  def order_responsible?(entry, user)
    entry.work_item && entry.order&.responsible_id == user.id
  end
end
