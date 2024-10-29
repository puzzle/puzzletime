# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: billing_addresses
#
#  id            :integer          not null, primary key
#  country       :string(2)
#  invoicing_key :string
#  street        :string
#  supplement    :string
#  town          :string
#  zip_code      :string
#  client_id     :integer          not null
#  contact_id    :integer
#
# Indexes
#
#  index_billing_addresses_on_client_id   (client_id)
#  index_billing_addresses_on_contact_id  (contact_id)
#
# }}}

Fabricator(:billing_address) do
  client
  street { Faker::Address.street_address }
  zip_code { Faker::Address.zip_code }
  town { Faker::Address.city }
end
