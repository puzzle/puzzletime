# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: workplaces
#
#  id   :bigint           not null, primary key
#  name :string
#

class Workplace < ApplicationRecord
  validates_by_schema
  validates :name, uniqueness: { case_sensitive: false }

  scope :list, -> { order(:name) }

  def to_s
    name
  end
end
