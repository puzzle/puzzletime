class ProjectOverviewPlanningGraph < OverviewPlanningGraph

  attr_reader :employee
  
  def initialize(project, plannings, period)
    super(period)
    @project = project
    add_plannings_to_cache(plannings)
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
      "free"
    else
      "full_planned"
    end
  end

  def week_label(week)
    "#{planned_percent(week)}%"
  end
  
end