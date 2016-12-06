# encoding: utf-8

module Plannings
  class EmployeeBoard < Board

    alias employee subject

    def initialize(employee, period)
      super(employee, period)
      @employments = employee.statistics.employments_during(period)
      @absences = employee.worktimes.joins(:absence).in_period(period).group(:work_date).sum(:hours)
      @holidays = Holiday.holidays(period).group_by(&:holiday_date)
    end

    def row_legend(_employee_id, work_item_id)
      accounting_posts.detect { |post| post.work_item_id == work_item_id.to_i }
    end

    def week_total(date)
      week_totals[date] + week_absences(date)
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
      @weekly_employment_percent[date] ||=
        compute_weekly_must_hours(date) / must_hours_per_week(date) * 100
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

    def week_absences(date)
      absence_hours = 7.times.sum { |i| @absences[date + i].to_f }
      absence_hours * 100 / must_hours_per_week(date)
    end

    def must_hours_per_week(date)
      # we ignore must hour changes during a single week
      must_hours_per_day(date) * 5
    end

    def must_hours_per_day(date)
      @must_hours_per_day ||= {}
      @must_hours_per_day[date] ||= WorkingCondition.value_at(date, :must_hours_per_day)
    end

    def compute_weekly_must_hours(date)
      @employments.each_with_index do |e, i|
        hours = must_hours_for_employment(date, e, i)
        return hours if hours
      end
      0
    end

    def must_hours_for_employment(date, employment, i)
      period = employment.period
      if period.include?(date) && period.include?(date + 4)
        # employment covers entire week
        must_hours_for_single_employment(employment, date)
      elsif period.include?(date)
        # employment changes in the middle of the week
        # we assume max one employment change per week
        must_hours_for_multiple_employments(employment, date, i)
      elsif period.start_date > date && period.include?(date + 4)
        # first employment starts in the middle of the week
        must_hours_for_beginning_employment(employment, date)
      end
    end

    def must_hours_for_single_employment(employment, date)
      employment_must_hours_during(employment, date, date + 4)
    end

    def must_hours_for_multiple_employments(employment, date, i)
      hours = employment_must_hours_during(employment, date, employment.period.end_date)
      next_employment = @employments[i + 1]
      if next_employment && next_employment.start_date <= date + 4
        hours += employment_must_hours_during(next_employment, next_employment.start_date, date + 4)
      end
      hours
    end

    def must_hours_for_beginning_employment(employment, date)
      employment_must_hours_during(employment, employment.start_date, date + 4)
    end

    def employment_must_hours_during(employment, from, to)
      must_hours = must_hours_per_day(from)
      (from..to).sum do |date|
        daily_must_hours(date, must_hours) * employment.percent / 100.0
      end
    end

    def daily_must_hours(date, must_hours)
      @holidays[date].try(:first).try(:musthours_day) || must_hours
    end

  end
end
