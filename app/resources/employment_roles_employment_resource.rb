# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Read-only roles of an employment, visible with the employments the user can see; written through
# EmploymentResource.
class EmploymentRolesEmploymentResource < ApplicationResource
  model EmploymentRolesEmployment

  attributes_writable_by_default false

  attribute :employment_id, :integer
  attribute :employment_role_id, :integer
  attribute :employment_role_level_id, :integer
  attribute :percent, :big_decimal

  belongs_to :employment

  def base_scope
    EmploymentRolesEmployment.where(employment_id: EmploymentResource.new.base_scope.select(:id))
  end
end
