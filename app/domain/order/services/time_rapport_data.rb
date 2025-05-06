# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  module Services
    TimeRapportData = Struct.new(
      :order, :worktimes, :tickets, :ticket_view,
      :employees, :employee, :work_items, :period, keyword_init: true
    )
  end
end
