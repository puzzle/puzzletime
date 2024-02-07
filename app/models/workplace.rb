# frozen_string_literal: true

#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Workplace < ApplicationRecord
  validates_by_schema
  validates :name, uniqueness: { case_sensitive: false }

  scope :list, -> { order(:name) }

  def to_s
    name
  end
end
