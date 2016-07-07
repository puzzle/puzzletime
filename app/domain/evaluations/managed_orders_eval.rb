# encoding: utf-8

class ManagedOrdersEval < WorkItemsEval
  self.label             = 'Geleitete Aufträge'
  self.total_details     = false
  self.billable_hours    = true

  def category_label
    'Kunde: ' + division.order.client.name
  end

  def divisions(_period = nil)
    WorkItem.joins(:order).where(orders: { responsible_id: category.id }).list
  end

  def sum_times_grouped(period)
    query = Worktime.joins(:work_item).
      joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)').
      where(type: 'Ordertime').
      where(orders: { responsible_id: category.id }).
      in_period(period).
      group('orders.work_item_id')
    query_time_sums(query, 'orders.work_item_id')
  end

  def sum_total_times(period = nil)
    query = Worktime.joins(:work_item).
      joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)').
      where(type: 'Ordertime').
      where(orders: { responsible_id: category.id }).
      in_period(period)
    query_time_sums(query)
  end
end
