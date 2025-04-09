# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Invoice
  class Report
    class Total
      delegate :entries, to: :@report

      def initialize(report)
        @report = report
      end

      def to_s
        "Total (#{entries.count})"
      end

      def total_amount
        @total_amount ||= entries.sum(&:total_amount)
      end

      def total_hours
        @total_hours ||= entries.sum(&:total_hours)
      end
    end
  end
end
