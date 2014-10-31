module AccountingPostsHelper

  def order_has_other_accounting_posts(entry, order)
    order.accounting_posts.count > 0 && order.accounting_posts != [entry]
  end

  def days_from_hours(hours)
    hours.present? ? (hours / 8.0).round(2) : nil
  end

  def book_on_order?(entry, order)
    entry.work_item_id == order.work_item_id
  end
end