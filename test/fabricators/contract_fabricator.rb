#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: contracts
#
#  id             :integer          not null, primary key
#  number         :string           not null
#  start_date     :date             not null
#  end_date       :date             not null
#  payment_period :integer          not null
#  reference      :text
#  sla            :text
#  notes          :text
#

Fabricator(:contract) do
  order
  number { rand(1_000_000).to_i }
  start_date { Time.zone.today - 1.year }
  end_date { Time.zone.today + 1.year }
end
