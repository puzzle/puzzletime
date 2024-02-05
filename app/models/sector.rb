# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: sectors
#
#  id     :integer          not null, primary key
#  name   :string           not null
#  active :boolean          default(TRUE), not null
#

class Sector < ApplicationRecord
  has_many :clients, dependent: :nullify

  scope :list, -> { order(:name) }

  validates_by_schema
  validates :name, uniqueness: true

  def to_s
    name
  end
end
