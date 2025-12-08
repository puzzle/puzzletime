# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Evaluations
  class ManagedOrdersEval < Evaluations::WorkItemsEval
    self.label             = 'Geleitete Aufträge'
    self.division_column   = 'orders.work_item_id'
    self.total_details     = false
    self.billable_hours    = true
    self.planned_hours     = true
    def category_label_override_item
      division.order.client
    end

    def division_label_override_item
      division.order
    end

    def category_label
      "Kunde: #{division.order.client.name}"
    end

    def divisions(_period = nil, _times = nil)
      WorkItem.joins(:order).includes(:order).where(orders: { responsible_id: category.id }).list
    end

    def division_supplement(_user)
      {
        order_completed: { title: 'Abschluss erledigt' },
        order_committed: { title: 'Abschluss freigegeben' }
      }
    end

    private

    def worktime_query(receiver, period = nil, division = nil)
      if receiver == category
        Worktime
          .joins(:work_item)
          .joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)')
          .where(type: 'Ordertime')
          .where(orders: { responsible_id: category.id })
          .in_period(period)
      else
        super
      end
    end

    def planning_query(_receiver, _division = nil)
      Planning
        .joins(:work_item)
        .joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)')
        .joins('INNER JOIN accounting_posts ON accounting_posts.work_item_id = ANY (work_items.path_ids)')
        .where(orders: { responsible_id: category.id })
    end
  end
end
