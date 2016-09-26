module Plannings
  class Board

    attr_reader :period, :plannings, :absences

    def initialize(period, plannings, absences)
      @period = period
      @plannings = plannings
      @absences = absences
    end

    def items(employee_id, work_item_id)
      rows[key(employee_id, work_item_id)]
    end

    def work_days
      @work_days ||= @period.length / 7 * 5
    end

    def default_row(employee_id, work_item_id)
      @default_rows ||= []
      @default_rows << key(employee_id, work_item_id)
    end

    def rows
      @rows ||= build_rows
    end

    private

    def build_rows
      {}.tap do |rows|
        build_default_rows(rows)
        build_planning_rows(rows)
        add_absences_to_rows(rows)
      end
    end

    def build_default_rows(rows)
      Array(@default_rows).each do |key|
        rows[key] = empty_row
      end
    end

    def build_planning_rows(rows)
      plannings.each do |p|
        k = key(p.employee_id, p.work_item_id)
        rows[k] = empty_row unless rows.key?(k)
        index = item_index(p.date)
        rows[k][index] = p if index
      end
    end

    def add_absences_to_rows(rows)
      absences.each do |absence|
        rows.each do |key, items|
          if key.first == absence.employee_id
            index = item_index(absence.work_date)
            items[index] = absence if index
          end
        end
      end
    end

    def item_index(date)
      return if [0, 6, 7].include?(date.wday)
      diff = (date - period.start_date).to_i
      diff - (diff / 7 * 2).to_i
    end

    def key(employee_id, work_item_id)
      [employee_id, work_item_id]
    end

    def empty_row
      Array.new(work_days)
    end

  end
end