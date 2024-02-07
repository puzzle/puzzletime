# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  class Report
    class Entry < SimpleDelegator
      attr_reader :order, :accounting_posts, :hours, :invoices

      delegate :major_chance, :major_chance_value, :major_risk, :major_risk_value, to: :order

      def initialize(order, accounting_posts, hours, invoices)
        super(order)
        @order = order
        @accounting_posts = accounting_posts
        @hours = hours
        @invoices = invoices
      end

      def client
        work_item.path_names.lines.to_a.first.strip
      end

      def category
        work_item.path_ids.size > 2 ? work_item.path_names.lines.to_a.second.strip : nil
      end

      def offered_amount
        @offered ||= sum_accounting_posts { |id| post_value(id, :offered_total) }
      end

      def offered_rate
        @offered_rate ||=
          if offered_hours.positive?
            (offered_amount / offered_hours).to_d
          else
            rates = sum_accounting_posts { |id| post_value(id, :offered_rate) }
            rates.positive? ? rates / accounting_posts.size : nil
          end
      end

      def offered_hours
        @offered_hours ||= sum_accounting_posts { |id| post_value(id, :offered_hours) }
      end

      def supplied_amount
        @supplied ||= sum_accounting_posts { |id| post_value(id, :offered_rate) * post_hours(id) }
      end

      def supplied_hours
        @supplied_hours ||= sum_accounting_posts { |id| post_hours(id) }
      end

      def billable_amount
        @billable ||= sum_accounting_posts { |id| post_value(id, :offered_rate) * post_hours(id, true) }
      end

      def billable_hours
        @billable_hours ||= sum_accounting_posts { |id| post_hours(id, true) }
      end

      def billed_amount
        invoices[:total_amount].to_d
      end

      def billed_hours
        invoices[:total_hours].to_d
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

      def target(scope_id)
        targets.find { |t| t.target_scope_id == scope_id.to_i }
      end

      private

      def sum_accounting_posts(&)
        accounting_posts.keys.sum(&)
      end

      def post_hours(id, billable = nil)
        h = hours[id]
        return BigDecimal('0') unless h

        if billable.nil?
          h.values.sum.to_d
        else
          h[billable].to_d
        end
      end

      def post_value(id, key)
        accounting_posts[id][key] || 0
      end

      # caching these explicitly gives quite a performance benefit if many orders are exported
      def targets
        @targets ||= order.targets.to_a
      end
    end
  end
end
