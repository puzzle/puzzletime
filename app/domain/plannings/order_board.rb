# encoding: utf-8

module Plannings
  class OrderBoard < Board

    alias order subject

    def row_legend(employee_id, _work_item_id)
      employees.detect { |e| e.id == employee_id.to_i }
    end

    def plannable_hours
      accounting_posts.to_a.sum { |p| p.offered_hours.to_f }
    end

    def total_hours
      WorkingCondition.sum_with(:must_hours_per_day, Period.new(nil, nil)) do |period, val|
        sum_planning_percent(period) / 100.0 * val
      end
    end

    private

    def load_plannings
      super.
        joins(:work_item).
        where('? = ANY (work_items.path_ids)', order.work_item_id)
    end

    def load_accounting_posts
      order.accounting_posts.
        where(closed: false).
        includes(:work_item).
        list
    end

    def sum_planning_percent(period)
      Planning.
        in_period(period).
        joins(:work_item).
        where('? = ANY (work_items.path_ids)', order.work_item_id).
        sum(:percent)
    end

  end
end
