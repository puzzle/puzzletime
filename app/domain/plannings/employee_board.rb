# encoding: utf-8

module Plannings
  class EmployeeBoard < Board

    alias employee subject

    def initialize(employee, period)
      super(employee, period)
      @employments = employee.statistics.employments_during(period)
      @absences = employee.worktimes.joins(:absence).in_period(period).group(:work_date).sum(:hours)
    end

    def row_legend(_employee_id, work_item_id)
      accounting_posts.detect { |post| post.work_item_id == work_item_id.to_i }
    end

    def week_total(date)
      @week_percent ||= {}
      @week_percent[date] ||=
        week_totals[date] + week_absence_percent(date) + week_holiday_percent(date)
    end

    # date is always monday of the requested week
    def week_totals_state(date)
      total = week_total(date)
      employed = weekly_employment_percent(date)
      if total.zero? && employed.zero?
        :fully_planned
      elsif total.zero?

        nil
      elsif (total - employed).abs < 1
        :fully_planned
      elsif total > employed
        :over_planned
      else
        :under_planned
      end
    end

    # date is always monday of the requested week
    def weekly_employment_percent(date)
      @weekly_employment_percent ||= {}
      @weekly_employment_percent[date] ||= compute_weekly_percent(date)
    end

    def overall_free_capacity
      sum = 0
      @period.step(7) do |date|
        sum += weekly_employment_percent(date) - week_total(date)
      end
      sum
    end

    private

    def load_plannings
      super.where(employee_id: employee.id)
    end

    def load_employees
      [employee]
    end

    def week_absence_percent(date)
      absence_hours = 7.times.sum { |i| @absences[date + i].to_f }
      absence_hours / (must_hours_per_day(date) * 5) * 100
    end

    def week_holiday_percent(date)
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

    def must_hours_per_day(date)
      @must_hours_per_day ||= {}
      @must_hours_per_day[date] ||= WorkingCondition.value_at(date, :must_hours_per_day)
    end

    def compute_weekly_percent(date)
      @employments.each_with_index do |e, i|
        percent = percent_for_employment(date, e, i)
        return percent if percent
      end
      0
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
