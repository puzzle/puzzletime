# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class IdValue
  attr_reader :id, :label

  def initialize(id, label)
    @id = id
    @label = label
  end

  def to_s
    label
  end
end
