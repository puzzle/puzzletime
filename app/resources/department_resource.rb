# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Departments; visible to those who may read them by `Ability`.
class DepartmentResource < ApplicationResource
  include AbilityScoped

  model Department

  attribute :name, :string
  attribute :shortname, :string

  has_many :employees
end
