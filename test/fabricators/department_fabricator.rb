#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: departments
#
#  id        :integer          not null, primary key
#  name      :string(255)      not null
#  shortname :string(3)        not null
#

Fabricator(:department) do
  name { Faker::Company.suffix }
  shortname { ('A'..'Z').to_a.shuffle.take(2).join }
end
