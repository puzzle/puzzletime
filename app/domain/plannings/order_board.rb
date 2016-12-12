# encoding: utf-8

module Plannings
  class OrderBoard < Board

    alias order subject

    def row_legend(employee_id, _work_item_id)
      employees.detect { |e| e.id == employee_id.to_i }
    end

    def total_row_hours(employee_id, work_item_id)
      @total_row_hours ||= load_total_row_hours
      @total_row_hours[key(employee_id.to_i, work_item_id.to_i)] || 0
    end

    def plannable_hours
      accounting_posts.to_a.sum { |p| p.offered_hours.to_f }
    end

    # total planned hours on this order for all times, not limited to current period.
    def total_hours
      WorkingCondition.sum_with(:must_hours_per_day, Period.new(nil, nil)) do |period, val|
        load_plannings(period).sum(:percent) / 100.0 * val
      end
    end

    private

    def load_plannings(p = period)
      super(p).
        joins(:work_item).
        where('? = ANY (work_items.path_ids)', order.work_item_id)
    end

    def load_accounting_posts
      order.accounting_posts.
        where(closed: false).
        includes(:work_item).
        list
    end

    def load_total_row_hours
      hours = {}
      WorkingCondition.each_period_of(:must_hours_per_day, Period.new(nil, nil)) do |period, val|
        sums = load_plannings(period).
                 where(included_plannings_condition).
                 group(:employee_id, :work_item_id).
                 sum(:percent)
        sums.each do |(e, w), p|
          hours[key(e, w)] ||= 0
          hours[key(e, w)] += p / 100.0 * val
        end
      end
      hours
    end

  end
end
