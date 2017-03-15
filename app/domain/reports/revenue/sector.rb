# encoding: utf-8

module Reports::Revenue
  class Sector < Base

    self.grouping_model = ::Sector
    self.grouping_fk = :sector_id

    def load_entries
      super.where(active: true)
    end

    def load_ordertimes(period = past_period)
      super
        .joins('LEFT JOIN clients ON clients.work_item_id = ANY (work_items.path_ids)')
        .joins('LEFT JOIN sectors ON sectors.id = clients.sector_id')
        .where('sector_id IS NULL OR sectors.active = TRUE')
    end

    def load_plannings(period)
      super
        .joins('LEFT JOIN clients ON clients.work_item_id = ANY (work_items.path_ids)')
        .joins('LEFT JOIN sectors ON sectors.id = clients.sector_id')
        .where('sector_id IS NULL OR sectors.active = TRUE')
    end

  end
end
