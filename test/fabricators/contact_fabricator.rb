#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: contacts
#
#  id            :integer          not null, primary key
#  client_id     :integer          not null
#  lastname      :string
#  firstname     :string
#  function      :string
#  email         :string
#  phone         :string
#  mobile        :string
#  crm_key       :string
#  created_at    :datetime
#  updated_at    :datetime
#  invoicing_key :string
#

Fabricator(:contact) do
  client
  lastname { Faker::Name.last_name }
  firstname { Faker::Name.first_name }
end
