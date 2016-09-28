# encoding: utf-8

module Plannings
  class EmployeeBoard < Board

    alias_method :employee, :subject

    def initialize(employee, period)
      super(employee, period)
      @employments = employee.statistics.employments_during(period)
    end

    def week_totals_state(date)
      total = week_totals[date]
      employed = weekly_employment_percent(date)
      if (total - employed).abs < 1
        :fully_planned
      elsif total > employed
        :over_planned
      else
        :under_planned
      end
    end

    def row_legend(_employee_id, work_item_id)
      accounting_posts.detect { |post| post.work_item_id == work_item_id.to_i }
    end

    private

    def load_plannings
      super.where(employee_id: employee.id)
    end

    def load_employees
      [employee]
    end

    def weekly_employment_percent(date)
      @employments.each_with_index do |e, i|
        period = e.period
        if period.include?(date)
          return percent_for_employment(e, date, i)
        elsif period.start_date > date && period.include?(date + 4)
          # first employment starts in the middle of the week
          new_days = 5 - (period.start_date - date)
          return new_days * e.percent / 5.0
        end
      end
      0
    end

    def percent_for_employment(employment, date, i)
      period = employment.period
      if period.include?(date + 4)
        # employment covers entire week
        employment.percent
      else
        # employment changes in the middle of the week
        # we assume max one employment change per week
        next_percent = @employments[i + 1].try(:percent) || 0
        old_days = period.end_date - date + 1
        (old_days * employment.percent + (5 - old_days) * next_percent) / 5.0
      end
    end

  end
end
