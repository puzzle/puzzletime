# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  class Cockpit
    class AccountingPostRow < Row
      include Rails.application.routes.url_helpers

      attr_reader :cells, :accounting_post, :info

      def initialize(accounting_post, order, period, label = nil)
        super(label || accounting_post.to_s)
        @order = order
        @period = period
        @accounting_post = accounting_post
        @cells = build_cells
        @info = build_info
      end

      def portfolio
        accounting_post.portfolio_item.to_s
      end

      delegate :offered_rate, to: :accounting_post

      def supplied_services_hours
        accounting_post_hours.values.sum
      end

      def billable_hours
        accounting_post_hours[true] || 0
      end

      def to_end_billable_hours
        custom_acoounting_post_hours(Period.new(nil, @period.end_date))[true] || 0
      end

      def not_billable_hours
        accounting_post_hours[false] || 0
      end

      def overall_supplied_services_hours
        custom_acoounting_post_hours(Period.new(nil, nil)).values.sum
      end

      def overall_not_billable_hours
        custom_acoounting_post_hours(Period.new(nil, nil))[false] || 0
      end

      def shortnames
        accounting_post.work_item.path_shortnames
      end

      def name
        accounting_post.work_item.name
      end

      def future_plannings
        accounting_post.work_item.plannings.definitive.where('date > ?', @period.end_date)
      end

      def future_planned_hours
        future_plannings.sum(&:hours)
      end

      private

      def build_cells
        { budget: build_budget_cell,
          supplied_services: build_supplied_services_cell,
          not_billable: build_not_billable_cell,
          open_budget: build_open_budget_cell,
          planned_budget: build_planned_budget_cell }
      end

      def build_budget_cell
        Cell.new(accounting_post.offered_hours, accounting_post.offered_total, nil)
      end

      def build_supplied_services_cell
        build_cell_with_amount(
          supplied_services_hours,
          order_order_services_path(
            @order.id,
            work_item_ids: accounting_post.work_item.id,
            start_date: @period.start_date,
            end_date: @period.end_date
          )
        )
      end

      def build_not_billable_cell
        link_path = order_order_services_path(
          @order.id,
          work_item_ids: accounting_post.work_item.id,
          billable: false,
          start_date: @period.start_date,
          end_date: @period.end_date
        )
        Cell.new(not_billable_hours, calculate_amount(not_billable_hours), link_path)
      end

      def build_open_budget_cell
        hours = (accounting_post.offered_hours || 0) - to_end_billable_hours
        build_cell_with_amount(hours)
      end

      def build_planned_budget_cell
        build_cell_with_amount(future_planned_hours)
      end

      def build_cell_with_amount(hours, link = nil)
        Cell.new(hours, calculate_amount(hours), link)
      end

      def calculate_amount(hours)
        offered_rate && (offered_rate * hours.to_d)
      end

      def accounting_post_hours
        @hours = accounting_post.worktimes.in_period(@period).group(:billable).sum(:hours)
      end

      def custom_acoounting_post_hours(period)
        @overall_hours = accounting_post.worktimes.in_period(period).group(:billable).sum(:hours)
      end

      def build_info
        { overall_not_billable_hours:, overall_supplied_services_hours: }
      end
    end
  end
end
