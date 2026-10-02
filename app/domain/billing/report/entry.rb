# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Billing
  class Report
    class Entry < SimpleDelegator
      attr_reader :order, :worktimes, :accounting_posts, :hours, :invoices

      def initialize(order, worktimes, accounting_posts, hours, invoices)
        super(order)
        @order = order
        @worktimes = worktimes
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
        @offered_amount ||= sum_accounting_posts { |id| post_value(id, :offered_total) }
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

      def supplied_amount
        @supplied_amount ||= sum_accounting_posts { |id| post_value(id, :offered_rate) * post_hours(id) }
      end

      def supplied_hours
        @supplied_hours ||= sum_accounting_posts { |id| post_hours(id) }
      end

      def billable_amount
        @billable_amount ||= sum_accounting_posts { |id| post_value(id, :offered_rate) * post_hours(id, true) }
      end

      def billable_hours
        @billable_hours ||= sum_accounting_posts { |id| post_hours(id, true) }
      end

      def billed_amount
        invoiced_worktime_sum(true, 'amount')
      end

      def not_billed_hours
        invoiced_worktime_sum(false, 'hours')
      end

      def not_billed_amount
        invoiced_worktime_sum(false, 'amount')
      end

      private

      # worktimes: { invoiced? => { order_id => grouped Worktime row with 'hours' and 'amount' } }
      def invoiced_worktime_sum(invoiced, column)
        row = worktimes&.dig(invoiced, @order.id)
        row ? row[column] || 0 : 0
      end

      def sum_accounting_posts(&)
        accounting_posts.keys.sum(&)
      end

      def post_hours(id, billable = nil)
        h = hours[id]
        return BigDecimal(0) unless h

        if billable.nil?
          h.values.sum.to_d
        else
          h[billable].to_d
        end
      end

      def post_value(id, key)
        accounting_posts[id][key] || 0
      end
    end
  end
end
