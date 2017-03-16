# encoding: utf-8

module Reports::Revenue
  class PortfolioItem < Base

    self.grouping_model = ::PortfolioItem
    self.grouping_fk = :portfolio_item_id

  end
end
