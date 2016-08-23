# encoding: utf-8

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
        if ordertime_hours > 0
          100 * billable_hours / ordertime_hours
        else
          0
        end
      end

      private

      def must_hours_100_procent
        period.musttime
      end

    end
  end
end
