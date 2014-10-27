class Order::Cockpit

  attr_reader :order, :rows

  def initialize(order)
    @order = order
    @rows = build_rows
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

  def sub_levels?
    accounting_posts.size != 1 ||
    accounting_posts.first.work_item_id != order.work_item_id
  end

  def accounting_posts
    @accounting_posts ||= order.accounting_posts.includes(:portfolio_item).list.to_a
  end

end