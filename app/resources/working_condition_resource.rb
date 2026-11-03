# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Working conditions valid from a date on (decimals render as strings). Visible by `Ability`.
class WorkingConditionResource < ApplicationResource
  include AbilityScoped

  model WorkingCondition

  attribute :valid_from, :date
  attribute :vacation_days_per_year, :big_decimal
  attribute :must_hours_per_day, :big_decimal
end
