# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: accounting_posts
#
#  id                     :integer          not null, primary key
#  billable               :boolean          default(TRUE), not null
#  closed                 :boolean          default(FALSE), not null
#  description_required   :boolean          default(FALSE), not null
#  from_to_times_required :boolean          default(FALSE), not null
#  meal_compensation      :boolean          default(FALSE), not null
#  offered_hours          :float
#  offered_rate           :decimal(12, 2)
#  offered_total          :decimal(12, 2)
#  remaining_hours        :integer
#  ticket_required        :boolean          default(FALSE), not null
#  market_opportunity_id  :integer
#  portfolio_item_id      :integer
#  service_id             :integer
#  work_item_id           :integer          not null
#
# Indexes
#
#  index_accounting_posts_on_market_opportunity_id  (market_opportunity_id)
#  index_accounting_posts_on_portfolio_item_id      (portfolio_item_id)
#  index_accounting_posts_on_service_id             (service_id)
#  index_accounting_posts_on_work_item_id           (work_item_id)
#
# }}}

Fabricator(:accounting_post) do
  work_item { Fabricate(:work_item, parent_id: Fabricate(:order).work_item_id) }
  offered_rate { 120 }
  portfolio_item { PortfolioItem.first }
  service { Service.first }
end
