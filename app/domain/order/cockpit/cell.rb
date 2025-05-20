# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  class Cockpit
    Cell = Struct.new(:hours, :amount, :link) do
      def days
        hours / must_hours_per_day if hours
      end

      def must_hours_per_day
        WorkingCondition.todays_value(:must_hours_per_day)
      end
    end
  end
end
