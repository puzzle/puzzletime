# encoding: utf-8

class ProjectOverviewPlanningGraph < OverviewPlanningGraph

  attr_reader :employee

  def initialize(project, plannings, plannings_abstr, period)
    super(period)
    @project = project
    add_plannings_to_cache(plannings)
    add_plannings_to_cache(plannings_abstr)
  end

  def style(date)
    cached = @cache[date]
    if cached
      cached.style
    else
      'free'
    end
  end

  def week_style(week)
    if planned_percent(week) == 0
      'free'
    else
      'full_planned'
    end
  end

  def week_label(week)
    planned_perc = (planned_percent(week) * 100).round.to_f / 100 # round with precision of two digits after the point
    "#{planned_perc}%"
  end

end
