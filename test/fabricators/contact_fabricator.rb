# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: contacts
#
#  id            :integer          not null, primary key
#  crm_key       :string
#  email         :string
#  firstname     :string
#  function      :string
#  invoicing_key :string
#  lastname      :string
#  mobile        :string
#  phone         :string
#  created_at    :datetime
#  updated_at    :datetime
#  client_id     :integer          not null
#
# Indexes
#
#  index_contacts_on_client_id  (client_id)
#
# }}}

Fabricator(:contact) do
  client
  lastname { Faker::Name.last_name }
  firstname { Faker::Name.first_name }
end
