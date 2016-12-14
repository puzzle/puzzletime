# encoding: utf-8

module PlanningsHelper
  def planning_legend_path(legend)
    case legend
    when Employee then plannings_employee_path(legend)
    when AccountingPost then plannings_order_path(legend.order)
    else raise ArgumentError, "invalid argument #{legend.inspect}"
    end
  end

  def planning_row_id(employee_id, work_item_id)
    "planning_row_employee_#{employee_id}_work_item_#{work_item_id}"
  end

  def months_from_monday
    mondays = []
    @period.step(7) { |date| mondays << date }
    mondays.uniq(&:at_beginning_of_month).map do |first|
      Period.new(first, [@period.end_date, first.at_end_of_month].min)
    end
  end

  def company_week_total(date)
    @company_week_total ||= {}
    @company_week_total[date] ||= @boards.sum { |board| board.week_total(date) }
  end

  def company_weekly_employment_percent(date)
    @company_weekly_employment_percent ||= {}
    @company_weekly_employment_percent[date] ||=
      @boards.sum { |board| board.weekly_employment_percent(date) }
  end

  # date is always monday of the requested week
  def company_week_totals_state(date)
    total = company_week_total(date)
    employed = company_weekly_employment_percent(date)
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
end
