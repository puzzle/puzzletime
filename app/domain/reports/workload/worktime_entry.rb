class Reports::Workload::WorktimeEntry < Struct.new(*Reports::Workload::WORKTIME_FIELDS, :order_work_item)

  delegate :company_work_item_id, to: :class

  class << self
    def company_work_item_id
      @company_work_item_id ||= Client.find(Settings.clients.id_of_ourselfs).work_item_id
    end
  end

  def absencetime?
    type == Absencetime.name
  end

  def ordertime?
    type == Ordertime.name
  end

  def external_client?
    Array.wrap(path_ids).exclude?(company_work_item_id)
  end
end
