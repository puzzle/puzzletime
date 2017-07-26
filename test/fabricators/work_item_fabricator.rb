# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: work_items
#
#  id              :integer          not null, primary key
#  parent_id       :integer
#  name            :string           not null
#  shortname       :string(5)        not null
#  description     :text
#  path_ids        :integer          is an Array
#  path_shortnames :string
#  path_names      :string(2047)
#  leaf            :boolean          default(TRUE), not null
#  closed          :boolean          default(FALSE), not null
#

Fabricator(:work_item) do
  name { Faker::Company.name }
  shortname { ('A'..'Z').to_a.shuffle.take(4).join }
end
