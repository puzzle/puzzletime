#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class Order::Cockpit
  class AccountingPostRow < Row
    attr_reader :cells, :accounting_post

    def initialize(accounting_post, label = nil)
      super(label || accounting_post.to_s)
      @accounting_post = accounting_post
      @cells = build_cells
    end

    def portfolio
      accounting_post.portfolio_item.to_s
    end

    def offered_rate
      accounting_post.offered_rate
    end

    def supplied_services_hours
      accounting_post_hours.values.sum
    end

    def not_billable_hours
      accounting_post_hours[false] || 0
    end

    def shortnames
      accounting_post.work_item.path_shortnames
    end

    def name
      accounting_post.work_item.name
    end

    private

    def build_cells
      { budget:              build_budget_cell,
        supplied_services:   build_supplied_services_cell,
        open_services:       build_open_services_cell,
        not_billable:        build_not_billable_cell }
    end

    def build_budget_cell
      Cell.new(accounting_post.offered_hours, accounting_post.offered_total)
    end

    def build_supplied_services_cell
      build_cell_with_amount(supplied_services_hours)
    end

    def build_not_billable_cell
      Cell.new(not_billable_hours, calculate_amount(not_billable_hours))
    end

    def build_open_services_cell
      hours = (accounting_post.offered_hours || 0) - supplied_services_hours
      build_cell_with_amount(hours)
    end

    def build_cell_with_amount(hours)
      Cell.new(hours, calculate_amount(hours))
    end

    def calculate_amount(hours)
      offered_rate && offered_rate * hours.to_d
    end

    def accounting_post_hours
      @hours ||= accounting_post.worktimes.group(:billable).sum(:hours)
    end
  end
end
