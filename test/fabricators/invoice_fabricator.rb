# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: invoices
#
#  id                 :integer          not null, primary key
#  billing_date       :date             not null
#  due_date           :date             not null
#  grouping           :integer          default("accounting_posts"), not null
#  invoicing_key      :string
#  period_from        :date             not null
#  period_to          :date             not null
#  reference          :string           not null
#  status             :string           not null
#  total_amount       :decimal(12, 2)   not null
#  total_hours        :float            not null
#  created_at         :datetime
#  updated_at         :datetime
#  billing_address_id :integer          not null
#  order_id           :integer          not null
#
# Indexes
#
#  index_invoices_on_billing_address_id  (billing_address_id)
#  index_invoices_on_order_id            (order_id)
#
# }}}

Fabricator(:invoice) do
  order
  billing_address { |attrs| Fabricate(:billing_address, client: attrs[:order].client) }
  work_items(count: 2)
  employees(count: 2)
  billing_date { Time.zone.today }
  period_from { (Time.zone.today - 1.month).at_beginning_of_month }
  period_to { (Time.zone.today - 1.month).at_end_of_month }
end
