# == Schema Information
#
# Table name: accounting_posts
#
#  id                     :integer          not null, primary key
#  work_item_id           :integer          not null
#  portfolio_item_id      :integer
#  offered_hours          :float
#  offered_rate           :decimal(12, 2)
#  offered_total          :decimal(12, 2)
#  remaining_hours        :integer
#  billable               :boolean          default(TRUE), not null
#  description_required   :boolean          default(FALSE), not null
#  ticket_required        :boolean          default(FALSE), not null
#  from_to_times_required :boolean          default(FALSE), not null
#  closed                 :boolean          default(FALSE), not null
#  service_id             :integer
#

Fabricator(:accounting_post) do
  work_item { Fabricate(:work_item, parent_id: Fabricate(:order).work_item_id) }
  offered_rate { 120 }
  portfolio_item { PortfolioItem.first }
  service { Service.first }
end
