# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: absences
#
#  id       :integer          not null, primary key
#  name     :string(255)      not null
#  payed    :boolean          default(FALSE)
#  vacation :boolean          default(FALSE), not null
#

class Absence < ApplicationRecord
  include Evaluatable

  # All dependencies between the models are listed below
  has_many :worktimes
  has_many :employees, through: :worktimes

  protect_if :worktimes, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Arbeitszeiten zugeordnet sind'

  # Validation helpers
  validates_by_schema
  validates :name, uniqueness: true

  scope :list, -> { order(:name) }

  def to_s
    name
  end
end
