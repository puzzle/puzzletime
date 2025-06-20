# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Billing
  class Report
    class Entry < SimpleDelegator
      attr_reader :order, :accounting_posts, :hours, :invoices, :invoice_flatrates, :flatrates

      def initialize(order, worktimes, accounting_posts, hours, invoices, invoice_flatrates, flatrates)
        super(order)
        @order = order
        @worktimes = worktimes
        @accounting_posts = accounting_posts
        @hours = hours
        @invoices = invoices
        @invoice_flatrates = invoice_flatrates
        @flatrates = flatrates
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
        return 0 unless @worktimes.present? && @worktimes[true].present?

        entry = @worktimes[true][@order.id]
        entry.present? ? entry['amount'] || 0 : 0
      end

      def not_billed_hours
        return 0 unless @worktimes.present? && @worktimes[false].present?

        entry = @worktimes[false][@order.id]
        entry.present? ? entry['hours'] || 0 : 0
      end

      def not_billed_amount
        return 0 unless @worktimes.present? && @worktimes[false].present?

        entry = @worktimes[false][@order.id]
        entry.present? ? entry['amount'] || 0 : 0
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

      def target(scope_id)
        targets.find { |t| t.target_scope_id == scope_id.to_i }
      end

      def billed_invoice_flatrates_total_amount
        invoice_flatrates[:total_amount].to_d
      end

      def billed_invoice_flatrates_total_quantity
        invoice_flatrates[:total_quantity].to_i
      end

      def planned_flatrates_total_amount
        flatrates[:planned_flatrates_total_amount].to_d
      end

      def planned_flatrates_total_quantity
        flatrates[:planned_flatrates_total_quantity].to_i
      end

      private

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

      # caching these explicitly gives quite a performance benefit if many orders are exported
      def targets
        @targets ||= order.targets.to_a
      end
    end
  end
end
