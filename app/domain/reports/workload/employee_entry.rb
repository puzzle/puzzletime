# encoding: utf-8

module Reports
  class Workload
    class EmployeeEntry < BaseEntry
      attr_reader :employee

      delegate :to_s, to: :employee

      def initialize(employee, period, employments, worktimes)
        @employee = employee
        super(period, employments, worktimes)
      end

      def order_entries
        @order_entries ||= build_entries
      end

      alias entries order_entries # TODO: remove

      private

      def build_entries
        ordertimes.group_by(&:order_work_item).map do |work_item, ordertimes|
          ordertime_hours = ordertimes.sum(&:hours)
          billable_hours = ordertimes.select(&:billable).sum(&:hours) || 0
          billability = billable_hours > 0 ? billable_hours / ordertime_hours : 0
          Reports::Workload::OrdertimeEntry.new(work_item, ordertime_hours, billability)
        end
      end
    end
  end
end
