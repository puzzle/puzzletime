# encoding: utf-8

module Reports::Revenue
  class PortfolioItem < Base

    self.grouping_model = ::PortfolioItem
    self.grouping_fk = :portfolio_item_id

    def load_entries
      super.where(active: true)
    end

    def load_ordertimes(period = past_period)
      super
        .joins(work_item: { accounting_post: :portfolio_item })
        .where(portfolio_items: { active: true })
    end

    def load_plannings(period)
      super
        .joins(work_item: { accounting_post: :portfolio_item })
        .where(portfolio_items: { active: true })
    end

  end
end
