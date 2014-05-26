# encoding: utf-8

class EmployeeOverviewPlanningGraph < OverviewPlanningGraph


  # TODO separate view helpers from this class
  include PlanningHelper

  attr_reader :employee

  def initialize(employee, plannings, plannings_abstr, absence_graph, period)
    super(period)
    @employee = employee
    add_absences_to_cache(absence_graph)
    add_plannings_to_cache(plannings)
    add_plannings_to_cache(plannings_abstr)
  end

  def week_style(week)
    employment_percent = employement_percent(week)
    employment_percent = employment_percent.present? ? employment_percent : 0
    planned = planned_percent(week)
    planned = planned.present? ? planned : 0
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
    (planned_percent(week) / 20.0 * 10).round.to_f / 10
  end

  def week_label(week)
    planned_perc = (planned_percent(week) * 10).round.to_f / 10
    "#{planned_perc}%/#{employement_percent(week)}%"
  end

  def label(date)
    cached = @cache[date]
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

end
