# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: orders
#
#  id                 :integer          not null, primary key
#  closed_at          :date
#  committed_at       :date
#  completed_at       :date
#  crm_key            :string
#  major_chance_value :integer
#  major_risk_value   :integer
#  created_at         :datetime
#  updated_at         :datetime
#  billing_address_id :integer
#  contract_id        :integer
#  department_id      :integer
#  kind_id            :integer
#  responsible_id     :integer
#  status_id          :integer
#  work_item_id       :integer          not null
#
# Indexes
#
#  index_orders_on_billing_address_id  (billing_address_id)
#  index_orders_on_contract_id         (contract_id)
#  index_orders_on_department_id       (department_id)
#  index_orders_on_kind_id             (kind_id)
#  index_orders_on_responsible_id      (responsible_id)
#  index_orders_on_status_id           (status_id)
#  index_orders_on_work_item_id        (work_item_id)
#
# }}}

Fabricator(:order) do
  work_item { Fabricate(:work_item, parent_id: Fabricate(:client).work_item_id) }
  department { Department.first }
  responsible { Employee.first }
  kind { OrderKind.list.first }
end
