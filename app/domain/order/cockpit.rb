#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order::Cockpit
  attr_reader :order, :rows

  EM_DASH = '―'.freeze

  def initialize(order)
    @order = order
    @rows = build_rows
  end

  def billed_amount
    @billed_amount ||= order.invoices.where.not(status: 'cancelled').sum(:total_amount).to_f
  end

  def budget_open
    total.cells[:budget].amount.to_f - billed_amount
  end

  # Ist-R[currency] / Ist-V[h]
  def billed_rate
    billable_hours > 0 ? billed_amount / billable_hours : nil
  end

  # Ist-R[h] / Ist[h] x 100
  def cost_effectiveness_current
    result = (order.invoices.where.not(status: 'cancelled').sum(:total_hours).to_f / total_hours) * 100.0
    result.finite? ? result.round : EM_DASH
  end

  # (Ist[h]-Ist-NV[h]) / Ist[h] x 100
  def cost_effectiveness_forecast
    result = (1 - not_billable_hours / total_hours) * 100.0
    result.finite? ? result.round : EM_DASH
  end

  def accounting_posts
    @accounting_posts ||= order.accounting_posts.includes(:portfolio_item).list.to_a
  end

  private

  def not_billable_hours
    total.cells[:not_billable].hours.to_f
  end

  def billable_hours
    total_hours - not_billable_hours
  end

  def total_hours
    total.cells[:supplied_services].hours.to_f
  end

  def build_rows
    if sub_levels?
      rows = accounting_posts.collect { |p| AccountingPostRow.new(p) }
      total = TotalRow.new(rows)
      [total, *rows]
    else
      [AccountingPostRow.new(accounting_posts.first, order.work_item.path_shortnames)]
    end
  end

  def total
    rows.first
  end

  def sub_levels?
    accounting_posts.size != 1 ||
      accounting_posts.first.work_item_id != order.work_item_id
  end
end
