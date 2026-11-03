# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Contact persons of clients. Only those who may read the model by `Ability` see rows.
class ContactResource < ApplicationResource
  include AbilityScoped

  model Contact

  attribute :client_id, :integer
  attribute :lastname, :string
  attribute :firstname, :string
  attribute :function, :string
  attribute :email, :string
  attribute :phone, :string
  attribute :mobile, :string
  attribute :crm_key, :string

  belongs_to :client
  has_many :billing_addresses
end
