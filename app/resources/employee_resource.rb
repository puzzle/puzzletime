# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Read-only.
class EmployeeResource < ApplicationResource
  model Employee

  attributes_writable_by_default false

  attribute :firstname, :string
  attribute :lastname, :string
  attribute :shortname, :string
  attribute :department_id, :integer
  attribute :workplace_id, :integer

  belongs_to :department
end
