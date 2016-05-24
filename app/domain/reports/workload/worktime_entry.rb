class Reports::Workload::WorktimeEntry < Struct.new(*Reports::Workload::WORKTIME_FIELDS, :order_work_item)
  OURSELFS_CLIENT = Client.find(Settings.clients.id_of_ourselfs)

  def absencetime?
    type == Absencetime.name
  end

  def ordertime?
    type == Ordertime.name
  end

  def external_client?
    Array.wrap(path_ids).exclude?(OURSELFS_CLIENT.work_item_id)
  end
end