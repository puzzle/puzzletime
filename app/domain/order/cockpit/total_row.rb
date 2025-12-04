# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  class Cockpit
    class TotalRow < Row
      include Rails.application.routes.url_helpers
      attr_reader :info, :order, :period

      def initialize(order, period, rows)
        super('Total')
        @order = order
        @period = period
        @cells = build_total_cells(rows)
        @info = build_info(rows)
      end

      private

      def build_total_cells(rows)
        cells = rows.collect(&:cells)
        master = cells.first
        hash = {}
        master&.each_key do |key|
          hash[key] =
            Cell.new(sum_non_nil_values(cells, key, :hours, :to_d),
                     sum_non_nil_values(cells, key, :amount, :to_d),
                     link_path)
        end
        hash
      end

      # collect the info hash of every row and sum the individual values up (per key)
      def build_info(rows)
        infos = rows.collect(&:info)
        infos.each_with_object(Hash.new(0)) do |row, acc|
          row.each { |key, value| acc[key] += value }
        end
      end

      def sum_non_nil_values(cells, key, field, converter)
        values = cells.collect { |c| c[key].send(field) }
        return if values.all?(&:nil?)

        values.sum(&converter)
      end

      def link_path
        @link_path ||= order_order_services_path(
          @order.id,
          start_date: @period.start_date,
          end_date: @period.end_date
        )
      end
    end
  end
end
