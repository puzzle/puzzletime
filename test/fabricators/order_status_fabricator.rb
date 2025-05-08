# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: order_statuses
#
#  id       :integer          not null, primary key
#  closed   :boolean          default(FALSE), not null
#  default  :boolean          default(FALSE), not null
#  name     :string           not null
#  position :integer          not null
#  style    :string
#
# Indexes
#
#  index_order_statuses_on_name      (name) UNIQUE
#  index_order_statuses_on_position  (position)
#
# }}}

Fabricator(:order_status) do
  name { Faker::Hacker.ingverb }
  style { 'success' }
end
