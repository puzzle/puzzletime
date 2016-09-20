module Plannings
  class Board

    attr_reader :period, :plannings

    def initialize(period, plannings)
      @period = period
      @plannings = plannings
    end

    def row(employee_id, work_item_id)
      rows[key(employee_id, work_item_id)]
    end

    def rows
      @rows ||= build_rows
    end

    private

    def build_rows
      rows = Hash.new { |h, k| h[k] = Array.new(period.length) }
      plannings.each do |p|
        rows[key(p.employee_id, p.work_item_id)][p.date - period.start_date] = p
      end
      rows
    end

    def key(employee_id, work_item_id)
      [employee_id, work_item_id]
    end

  end
end