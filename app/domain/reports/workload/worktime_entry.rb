class Reports::Workload::WorktimeEntry < Struct.new(*Reports::Workload::WORKTIME_FIELDS, :order_work_item)

  def absencetime?
    type == Absencetime.name
  end

  def ordertime?
    type == Ordertime.name
  end

  def external_client?
    Array.wrap(path_ids).exclude?(Company.work_item_id)
  end
end
