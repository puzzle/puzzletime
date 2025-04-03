# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  class Cockpit
    class TotalRow < Row
      attr_reader :order_info

      def initialize(rows)
        super('Total')
        @cells = build_total_cells(rows)
        @order_info = build_order_info(rows)
      end

      private

      def build_total_cells(rows)
        cells = rows.collect(&:cells)
        master = cells.first
        hash = {}
        master&.each_key do |key|
          hash[key] =
            Cell.new(sum_non_nil_values(cells, key, :hours, :to_d),
                     sum_non_nil_values(cells, key, :amount, :to_d))
        end
        hash
      end

      # collect the row_info hash of every row and sum the individual values up (per key)
      def build_order_info(rows)
        row_infos = rows.collect(&:row_info)
        row_infos.each_with_object(Hash.new(0)) do |row, acc|
          row.each { |key, value| acc[key] += value }
        end
      end

      def sum_non_nil_values(cells, key, field, converter)
        values = cells.collect { |c| c[key].send(field) }
        return if values.all?(&:nil?)

        values.sum(&converter)
      end
    end
  end
end
