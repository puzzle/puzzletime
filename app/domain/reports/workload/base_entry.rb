# encoding: utf-8

module Reports
  class Workload
    class BaseEntry
      attr_reader :period, :employments, :worktimes

      def initialize(period, employments, worktimes)
        @period = period
        @employments = employments
        @worktimes = worktimes
      end

      def must_hours
        @must_hours ||= employments.sum { |e| e.musttime(period) }
      end

      def absencetime_hours
        @absencetime_hours ||= absencetimes.sum(&:hours)
      end

      def ordertime_hours
        @ordertime_hours ||= ordertimes.sum(&:hours)
      end

      def paid_absence_hours
        absencetimes.select(&:payed).sum(&:hours)
      end

      def worktime_balance
        ordertime_hours + paid_absence_hours - must_hours
      end

      def external_client_hours
        @external_client_hours ||= ordertimes_external_clients.sum(&:hours)
      end

      def billable_hours
        @billable_hours ||= ordertimes_external_clients.select(&:billable).sum(&:hours)
      end

      def workload
        ordertime_hours > 0 ? 100 * external_client_hours / ordertime_hours : 0
      end

      def billability
        external_client_hours > 0 ? 100 * billable_hours / external_client_hours : 0
      end

      private

      def ordertimes
        worktimes.select(&:ordertime?)
      end

      def absencetimes
        worktimes.select(&:absencetime?)
      end

      def ordertimes_external_clients
        ordertimes.select(&:external_client?)
      end
    end
  end
end
