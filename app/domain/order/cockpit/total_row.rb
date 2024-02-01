#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order::Cockpit
  class TotalRow < Row
    def initialize(rows)
      super('Total')
      @cells = build_total_cells(rows)
    end

    private

    def build_total_cells(rows)
      cells = rows.collect(&:cells)
      master = cells.first
      hash = {}
      if master
        master.keys.each do |key|
          hash[key] =
            Cell.new(sum_non_nil_values(cells, key, :hours, :to_d),
                     sum_non_nil_values(cells, key, :amount, :to_d))
        end
      end
      hash
    end

    def sum_non_nil_values(cells, key, field, converter)
      values = cells.collect { |c| c[key].send(field) }
      return if values.all?(&:nil?)

      values.sum(&converter)
    end
  end
end
