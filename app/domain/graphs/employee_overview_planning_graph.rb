# encoding: utf-8

class EmployeeOverviewPlanningGraph < OverviewPlanningGraph

  include PeriodIterable

  attr_reader :employee

  def initialize(employee, plannings, plannings_abstr, absence_graph, period)
    super(period)
    @employee = employee
    add_absences_to_cache(absence_graph)
    add_plannings_to_cache(plannings)
    add_plannings_to_cache(plannings_abstr)
  end

  def week_style(week)
    employment_percent = employement_percent(week) || 0
    planned = planned_percent(week) || 0
    free = employment_percent - planned
    if free == 0
      'full_planned'
    elsif planned > employment_percent
      'over_planned'
    elsif free < employment_percent
      'half_planned'
    else
      'free'
    end
  end

  def planned_days(week)
    (planned_percent(week) / 20.0).round(1)
  end

  def period_load
    if period_average_employment_percent > 0
      period_average_planned_percent.to_f / period_average_employment_percent.to_f
    else
      Float::INFINITY
    end
  end

  def week_label(week)
    planned_perc = planned_percent(week).round(1)
    "#{planned_perc}%/#{employement_percent(week)}%"
  end

  def label(date)
    cached = cache[date]
    cached.label if cached
  end

  private
  def add_absences_to_cache(absence_graph)
    absence_graph.each_day do |date|
      absence = absence_graph.absence(date)
      if absence
        add_to_cache(absence.label, date, absence.percent)
        add_to_cache(absence.label, date, absence.percent)
        # TODO: implement real half day absences
      end
    end
  end

  def employement_percent(date)
    employments = @employee.employments.select { |e| e.start_date <= date && (e.end_date.nil? or e.end_date >= date) }
    employments[0].percent if employments.size == 1
  end

  def period_average_employment_percent
    weeks_percents = enumerate_weeks.map {|week| employement_percent(week) || 0 }
    weeks_percents.sum / weeks_percents.size.to_f
  end

end
