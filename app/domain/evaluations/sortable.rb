# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Evaluations
  # Shared sort_dir handling for Evaluations backed by a sort_conditions hash
  # ({'sort' => ..., 'sort_dir' => ...}), e.g. from EvaluatorController#sort_conditions.
  module Sortable
    def sort_direction
      sort_conditions && sort_conditions['sort_dir'] == 'desc' ? :desc : :asc
    end

    def sort_multiplier
      sort_direction == :desc ? -1 : 1
    end

    private

    # times has exactly one entry: this sort is only offered for a single period.
    def period_hours_value(employee, times)
      times&.first&.dig(employee.id).to_f
    end
  end
end
