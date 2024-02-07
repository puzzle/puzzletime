# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: orders
#
#  id                 :integer          not null, primary key
#  work_item_id       :integer          not null
#  kind_id            :integer
#  responsible_id     :integer
#  status_id          :integer
#  department_id      :integer
#  contract_id        :integer
#  billing_address_id :integer
#  crm_key            :string
#  created_at         :datetime
#  updated_at         :datetime
#  completed_at       :date
#  committed_at       :date
#  closed_at          :date
#  major_risk_value   :integer
#  major_chance_value :integer
#

Fabricator(:order) do
  work_item { Fabricate(:work_item, parent_id: Fabricate(:client).work_item_id) }
  department { Department.first }
  responsible { Employee.first }
  kind { OrderKind.list.first }
end
