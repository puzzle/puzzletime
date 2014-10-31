class Order::Cockpit

  attr_reader :order, :rows

  def initialize(order)
    @order = order
    @rows = build_rows
  end

  def avarage_rate
    # Ist-R[CHF] / (Ist[h] per letztem Rechnungsdatum)
  end

  def progress
    # 100/(Ist[h] + RA[h])*Ist[h]
  end

  def cost_effectiveness_current
    if total.cells[:budget].hours
      ((total.cells[:supplied_services].hours.to_i / total.cells[:budget].hours) * 100).round
    end
  end

  def cost_effectiveness_forecast
    # (Ist[h] + RA[h])/ Soll[h] x 100
  end

  def accounting_posts
    @accounting_posts ||= order.accounting_posts.includes(:portfolio_item).list.to_a
  end

  private

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