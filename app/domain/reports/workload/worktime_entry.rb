class Reports::Workload::WorktimeEntry < Struct.new(*Reports::Workload::WORKTIME_FIELDS, :order_work_item)

  delegate :ourselfs_client, to: :class

  class << self
    def ourselfs_client
      @ourselfs_client ||= Client.find(Settings.clients.id_of_ourselfs)
    end
  end

  def absencetime?
    type == Absencetime.name
  end

  def ordertime?
    type == Ordertime.name
  end

  def external_client?
    Array.wrap(path_ids).exclude?(ourselfs_client.work_item_id)
  end
end