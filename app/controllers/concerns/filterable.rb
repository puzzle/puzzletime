#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Filterable
  private

  def filter_entries_by(entries, *keys)
    keys.inject(entries) do |filtered, key|
      if params[key].present?
        filtered.where(key => params[key])
      else
        filtered
      end
    end
  end

  def filter_entries_allow_empty_by(entries, empty_param, *keys)
    keys.inject(entries) do |filtered, key|
      if params[key] == empty_param
        filtered.where(key => ['', nil])
      else
        filter_entries_by(filtered, key)
      end
    end
  end
end
