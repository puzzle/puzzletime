# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Whether a report's params carry an actual filter. Not part of Filterable:
# controllers include that one, and a public method there would become an action.
module ReportFilters
  NON_FILTER_PARAMS = %i[action controller format utf8 page clear].freeze

  def filters_defined?
    params.except(*NON_FILTER_PARAMS, *ignored_filter_params).values.any?(&:present?)
  end

  private

  # Params that choose a view of the report rather than filter its data.
  def ignored_filter_params = []
end
