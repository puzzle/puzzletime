# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Employment roles. Only those who may read the model by `Ability` see rows.
class EmploymentRoleResource < ApplicationResource
  include AbilityScoped

  model EmploymentRole

  attribute :name, :string
  attribute :billable, :boolean
  attribute :level, :boolean
  attribute :employment_role_category_id, :integer

  belongs_to :employment_role_category
end
