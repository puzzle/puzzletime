# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Management only (Ability: no rule for anybody else). The employee can only be set on creation.
class OvertimeVacationResource < ApplicationResource
  model OvertimeVacation

  self.default_sort = [{ transfer_date: :desc }]

  attribute :employee_id, :integer
  attribute :hours, :float
  attribute :transfer_date, :date

  belongs_to :employee

  def base_scope
    management? ? OvertimeVacation.all : OvertimeVacation.none
  end

  before_attributes only: [:update] do |attributes|
    attributes.delete(:employee_id)
  end
end
