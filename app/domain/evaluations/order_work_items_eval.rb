class OrderWorkItemsEval < WorkItemsEval

  def initialize(order_id, work_item_id)
    entry = work_item_id.present? ? WorkItem.find(work_item_id) : Order.find(order_id)
    super(entry)
  end

end