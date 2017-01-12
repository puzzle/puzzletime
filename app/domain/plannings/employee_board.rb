# encoding: utf-8

module Plannings
  class EmployeeBoard < Board

    class << self

      def week_planning_state(total, employed)
        if total.zero? && !employed.nil? && employed.zero?
          :fully_planned
        elsif total.zero?
          nil
        elsif (total - employed.to_f).abs < 1
          :fully_planned
        elsif total > employed.to_f
          :over_planned
        else
          :under_planned
        end
      end

    end

    alias employee subject

    def load_employments
      employee.statistics.employments_during(period)
    end

    def row_legend(_employee_id, work_item_id)
      accounting_posts.detect { |post| post.work_item_id == work_item_id }
    end

    def row_sum(accounting_post)
      accounting_post
    end

    def weekly_planned_percent(date)
      rows # assert data is loaded
      @weekly_planned_and_absence_percent ||= {}
      @weekly_planned_and_absence_percent[date] ||=
        weekly_planned_percents[date] + weekly_absence_percent(date) + weekly_holiday_percent(date)
    end

    # date is always monday of the requested week
    def week_planning_state(date)
      self.class.week_planning_state(weekly_planned_percent(date), weekly_employment_percent(date))
    end

    # date is always monday of the requested week
    def weekly_employment_percent(date)
      @weekly_employment_percent ||= {}
      if @weekly_employment_percent.key?(date) # ||= does not work if nil values are possible
        @weekly_employment_percent[date]
      else
        @weekly_employment_percent[date] = compute_weekly_employment_percent(date)
      end
    end

    def overall_free_capacity
      sum = 0
      @period.step(7) do |date|
        sum += weekly_employment_percent(date).to_f - weekly_planned_percent(date)
      end
      sum
    end

    def total_plannable_hours
      employee.statistics.musttime(period)
    end

    # total planned hours on this employee for the current period.
    def total_planned_hours
      rows # assert data is loaded
      WorkingCondition.sum_with(:must_hours_per_day, period) do |p, val|
        load_plannings(p).sum(:percent) / 100.0 * val
      end +
        @absencetimes.to_a.sum(&:hours)
    end

    private

    def load_plannings(p = period)
      super(p).where(employee_id: employee.id)
    end

    def load_employees
      [employee]
    end

    def included_employee_ids
      [employee.id]
    end

    def weekly_absence_percent(date)
      week = date..(date + 6)
      absence_hours = @absencetimes.select { |t| week.cover?(t.work_date) }.sum(&:hours)
      absence_hours / (must_hours_per_day(date) * 5) * 100
    end

    def weekly_holiday_percent(date)
      must_hours = must_hours_per_day(date)
      @employments.each_with_index do |e, i|
        percent = percent_for_employment(date, e, i) do |d|
          if @holidays[d]
            (must_hours - @holidays[d].to_f) / must_hours
          else
            0
          end
        end
        return percent if percent
      end
      0
    end

    def compute_weekly_employment_percent(date)
      rows # assert data is loaded
      @employments.each_with_index do |e, i|
        percent = percent_for_employment(date, e, i)
        return percent if percent
      end
      nil
    end

    def percent_for_employment(date, employment, i, &block)
      period = employment.period
      if period.include?(date) && period.include?(date + 4)
        # employment covers entire week
        employment_percent_during(employment, date, date + 4, &block)
      elsif period.include?(date)
        # employment changes in the middle of the week
        # we assume max one employment change per week
        percent_for_multiple_employments(employment, date, i, &block)
      elsif period.start_date > date && period.include?(date + 4)
        # first employment starts in the middle of the week
        employment_percent_during(employment, employment.start_date, date + 4, &block)
      end
    end

    def percent_for_multiple_employments(employment, date, i, &block)
      percent = employment_percent_during(employment, date, employment.period.end_date, &block)
      next_employment = @employments[i + 1]
      if next_employment && next_employment.start_date <= date + 4
        percent += employment_percent_during(next_employment, next_employment.start_date, date + 4, &block)
      end
      percent
    end

    def employment_percent_during(employment, from, to)
      (from..to).sum do |date|
        employment.percent * (block_given? ? yield(date) : 1) / 5.0
      end
    end

  end
end
