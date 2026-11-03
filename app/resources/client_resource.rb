# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Mirrors ClientsController: only management and order responsibles see and write clients. The work item (name,
# shortname, description) is written as a sidepost; a client's work item has no parent.
class ClientResource < ApplicationResource
  include AbilityScoped

  model Client

  attribute :crm_key, :string
  attribute :allow_local, :boolean
  attribute :sector_id, :integer
  attribute :e_bill_account_key, :string
  attribute :work_item_id, :integer, writable: false

  %i[name shortname].each do |delegated|
    attribute delegated, :string, writable: false, filterable: false, sortable: false do
      @object.public_send(delegated)
    end
  end

  belongs_to :work_item, link: false
  belongs_to :sector
  has_many :contacts
  has_many :billing_addresses

  def base_scope
    super.list
  end

  def save(model, meta = nil)
    errors = model.errors
    errors.add(:'work_item.parent_id', 'muss leer sein') if model.work_item&.parent_id
    errors.add(:work_item_id, 'kann nicht geändert werden') if model.persisted? && model.work_item_id_changed?
    errors.any? ? model : super
  end
end
