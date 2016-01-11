Fabricator(:accounting_post) do
  work_item { Fabricate(:work_item, parent_id: Fabricate(:order).work_item_id) }
  offered_rate { 120 }
  portfolio_item { PortfolioItem.first }
  service { Service.first }
end
