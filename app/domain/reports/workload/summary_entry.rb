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
        must_hours / must_hours_100procent
      end

      def absolute_billability
        100 * billable_hours / ordertime_hours
      end

      private

      def must_hours_100procent
        Employment.new(percent: 100, start_date: period.start_date, end_date: period.end_date).musttime
      end
    end
  end
end