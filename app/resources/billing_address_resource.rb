# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Billing addresses of clients; deletion is protected by the model while invoices exist. Visible by `Ability`.
class BillingAddressResource < ApplicationResource
  include AbilityScoped

  model BillingAddress

  attribute :client_id, :integer
  attribute :contact_id, :integer
  attribute :supplement, :string
  attribute :street, :string
  attribute :zip_code, :string
  attribute :town, :string
  attribute :country, :string

  belongs_to :client
  belongs_to :contact
end
