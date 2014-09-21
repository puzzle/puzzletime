# encoding: utf-8

class ManagedOrdersEval < WorkItemsEval

  self.label             = 'Geleitete Aufträge'
  self.total_details     = false

  def category_label
    'Kunde: ' + division.order.client.name
  end

  def divisions(period = nil)
    WorkItem.joins(:order).where(orders: { responsible_id: category.id }).list
  end

  def sum_times_grouped(period)
    Worktime.joins(:work_item).
             joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)').
             where(type: 'Ordertime').
             where(orders: { responsible_id: category.id }).
             in_period(period).
             group('orders.work_item_id').
             sum(:hours)
  end

  def sum_total_times(period = nil)
    Worktime.joins(:work_item).
             joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)').
             where(type: 'Ordertime').
             where(orders: { responsible_id: category.id }).
             in_period(period).
             sum(:hours).to_f
  end

end
