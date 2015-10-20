# encoding: UTF-8
class Order::Cockpit
  attr_reader :order, :rows

  EM_DASH = '―'

  def initialize(order)
    @order = order
    @rows = build_rows
  end

  def budget_billed
    @budget_billed ||= order.invoices.sum(:total_amount).to_f
  end

  def budget_open
    total.cells[:budget].amount.to_f - budget_billed
  end

  def average_rate
    # Ist-R[CHF] / (Ist[h] per letztem Rechnungsdatum)
    if last_invoice_date
      budget_billed / total_hours_at_last_invoice
    end
  end

  def cost_effectiveness_current
    # Ist-R[h] / Ist[h] x 100
    result = (order.invoices.sum(:total_hours).to_f / total_hours) * 100.0
    result.finite? ? result.round : EM_DASH
  end

  def cost_effectiveness_forecast
    # (Ist[h]-Ist-NV[h]) / Ist[h] x 100
    result = (1 - not_billable_hours / total_hours) * 100.0
    result.finite? ? result.round : EM_DASH
  end

  def accounting_posts
    @accounting_posts ||= order.accounting_posts.includes(:portfolio_item).list.to_a
  end

  private

  # hours by the last invoice date. including non-billable
  def total_hours_at_last_invoice
    order.worktimes.in_period(Period.new(nil, last_invoice_date)).sum(:hours).to_f
  end

  def not_billable_hours
    total.cells[:not_billable].hours.to_f
  end

  def total_hours
    total.cells[:supplied_services].hours.to_f
  end

  def last_invoice_date
    @last_invoice_date ||=
       order.invoices.select(:period_to).order(period_to: :desc).last.try(:period_to)
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
