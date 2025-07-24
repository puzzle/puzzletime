# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: clients
#
#  id                  :integer          not null, primary key
#  allow_local         :boolean          default(FALSE), not null
#  crm_key             :string
#  e_bill_account_key  :string
#  invoicing_key       :string
#  last_invoice_number :integer          default(0)
#  sector_id           :integer
#  work_item_id        :integer          not null
#
# Indexes
#
#  index_clients_on_sector_id     (sector_id)
#  index_clients_on_work_item_id  (work_item_id)
#
# }}}

Fabricator(:client) do
  work_item
end
