module Plannings
  class Board

    attr_reader :period, :plannings

    def initialize(period, plannings)
      @period = period
      @plannings = plannings
    end

    def items(employee_id, work_item_id)
      rows[key(employee_id, work_item_id)]
    end

    def work_days
      @work_days ||= @period.length / 7 * 5
    end

    def rows
      @rows ||= build_rows
    end

    private

    def build_rows
      plannings.each_with_object({}) do |p, rows|
        k = key(p.employee_id, p.work_item_id)
        rows[k] = Array.new(work_days) unless rows.key?(k)
        rows[k][item_index(p.date)] = p
      end
    end

    def item_index(date)
      diff = (date - period.start_date).to_i
      diff - (diff / 7 * 2).to_i
    end

    def key(employee_id, work_item_id)
      [employee_id, work_item_id]
    end

  end
end