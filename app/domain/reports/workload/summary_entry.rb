#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Reports
  class Workload
    class Reports::Workload::SummaryEntry < BaseEntry
      attr_reader :label

      def initialize(label, period, employments, worktimes)
        @label = label
        super(period, employments, worktimes)
      end

      def to_s
        label
      end

      def employment_fte
        must_hours / must_hours_100_procent
      end

      def absolute_billability
        ordertime_hours > 0 ? 100 * billable_hours / ordertime_hours : 0
      end

      private

      def must_hours_100_procent
        period.musttime
      end
    end
  end
end
