# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  module Report
    class Total
      delegate :entries, to: :@report

      def initialize(report)
        @report = report
      end

      def parent_names; end

      def to_s
        "Total (#{entries.count})"
      end

      def order
        nil
      end

      def status
        nil
      end

      def closed_at
        nil
      end

      def targets
        []
      end

      def major_chance
        nil
      end

      def major_risk
        nil
      end

      def offered_amount
        @offered_amount ||= entries.sum(&:offered_amount)
      end

      def offered_hours
        @offered_hours ||= entries.sum(&:offered_hours)
      end

      def supplied_amount
        entries.sum(&:supplied_amount)
      end

      def supplied_hours
        @supplied_hours ||= entries.sum(&:supplied_hours)
      end

      def billable_amount
        entries.sum(&:billable_amount)
      end

      def billable_hours
        entries.sum(&:billable_hours)
      end

      def billed_amount
        @billed_amount ||= entries.sum(&:billed_amount)
      end

      def billed_hours
        @billed_hours ||= entries.sum(&:billed_hours)
      end

      def offered_rate
        if offered_hours.positive?
          (offered_amount / offered_hours).to_d
        elsif !entries.empty?
          entries.filter_map(&:offered_rate).sum / entries.size
        end
      end

      def billability
        @billability ||= supplied_hours.positive? ? (billable_hours / supplied_hours * 100).round : nil
      end

      def billed_rate
        @billed_rate ||= billable_hours.positive? ? billed_amount / billable_hours : nil
      end

      def average_rate
        @average_rate ||= supplied_hours.positive? ? billable_amount / supplied_hours : nil
      end

      def target(_id); end
    end
  end
end
