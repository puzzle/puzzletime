# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: order_kinds
#
#  id   :integer          not null, primary key
#  name :string           not null
#
# Indexes
#
#  index_order_kinds_on_name  (name) UNIQUE
#
# }}}

Fabricator(:order_kind) do
  name { Faker::Hacker.noun }
end
