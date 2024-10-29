# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: work_items
#
#  id              :integer          not null, primary key
#  closed          :boolean          default(FALSE), not null
#  description     :text
#  leaf            :boolean          default(TRUE), not null
#  name            :string           not null
#  path_ids        :integer          is an Array
#  path_names      :string(2047)
#  path_shortnames :string
#  shortname       :string(5)        not null
#  parent_id       :integer
#
# Indexes
#
#  index_work_items_on_parent_id  (parent_id)
#  index_work_items_on_path_ids   (path_ids)
#
# }}}

Fabricator(:work_item) do
  name { Faker::Company.name }
  shortname { ('A'..'Z').to_a.shuffle.take(4).join }
end
