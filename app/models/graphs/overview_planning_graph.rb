class OverviewPlanningGraph
  include PlanningHelper
  
  def initialize(period)
    @period = period
    @cache = Hash.new
  end
  
  def style(date)
    cached = @cache[date]
    if cached
      cached.style
    else
     'free'
    end
  end
  
  def planned_percent(week)
    percent = 0
    week.step(week+5,1) do |date|
      cached = @cache[date]
      if cached
        percent += cached.percent
      end
    end
    percent
  end
    
protected
  def add_plannings_to_cache(plannings)
    plannings.each do |planning|
      if planning.repeat_type_no?
        add_week_to_cache(planning, Week::from_integer(planning.start_week).to_date)
      elsif planning.repeat_type_until?
        planning.start_week_date.step(planning.end_week_date, 7) do |week|
          if week >= @period.startDate && week <= @period.endDate
            add_week_to_cache(planning, week)
          end
        end
      else #forever
        planning.start_week_date.step(@period.endDate, 7) do |week|
          if week >= @period.startDate
            add_week_to_cache(planning, week)
          end
        end
      end
    end
  end
  
  def add_week_to_cache(planning, date)
    add_to_cache(planning.project.label, date) if planning.monday_am
    add_to_cache(planning.project.label, date) if planning.monday_pm
    date = date.next
    add_to_cache(planning.project.label, date) if planning.tuesday_am
    add_to_cache(planning.project.label, date) if planning.tuesday_pm
    date = date.next
    add_to_cache(planning.project.label, date) if planning.wednesday_am
    add_to_cache(planning.project.label, date) if planning.wednesday_pm
    date = date.next
    add_to_cache(planning.project.label, date) if planning.thursday_am
    add_to_cache(planning.project.label, date) if planning.thursday_pm
    date = date.next
    add_to_cache(planning.project.label, date) if planning.friday_am
    add_to_cache(planning.project.label, date) if planning.friday_pm
  end


  def add_to_cache(label, date)
    cached = @cache[date]
    unless cached
      cached = DayOverview.new
      @cache[date] = cached
    end
    cached.add(label)
  end
end