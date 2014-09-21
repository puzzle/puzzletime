# encoding: utf-8

class OverviewPlanningGraph

  # TODO separate view helpers from this class
  include PlanningHelper

  def initialize(period)
    @period = period
    @cache = {}
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
    week.step(week + 5, 1) do |date|
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
        add_week_to_cache(planning, Week.from_integer(planning.start_week).to_date)
      elsif planning.repeat_type_until?
        planning.start_week_date.step(planning.end_week_date, 7) do |week|
          if week >= @period.start_date && week <= @period.end_date
            add_week_to_cache(planning, week)
          end
        end
      else # forever
        planning.start_week_date.step(@period.end_date, 7) do |week|
          if week >= @period.start_date
            add_week_to_cache(planning, week)
          end
        end
      end
    end
  end

  def add_week_to_cache(planning, date)

    # abstract plannings which are quantified by a integer 'abstract_amount'
    if planning.is_abstract && planning.abstract_amount > 0
      add_to_cache(planning.work_item.label_verbose, date, planning.abstract_amount)

    # concrete plannings or abstract plannings which are quantified by means of a half-day selection
    else
      add_to_cache(planning.work_item.label_verbose, date) if planning.monday_am
      add_to_cache(planning.work_item.label_verbose, date) if planning.monday_pm
      date = date.next
      add_to_cache(planning.work_item.label_verbose, date) if planning.tuesday_am
      add_to_cache(planning.work_item.label_verbose, date) if planning.tuesday_pm
      date = date.next
      add_to_cache(planning.work_item.label_verbose, date) if planning.wednesday_am
      add_to_cache(planning.work_item.label_verbose, date) if planning.wednesday_pm
      date = date.next
      add_to_cache(planning.work_item.label_verbose, date) if planning.thursday_am
      add_to_cache(planning.work_item.label_verbose, date) if planning.thursday_pm
      date = date.next
      add_to_cache(planning.work_item.label_verbose, date) if planning.friday_am
      add_to_cache(planning.work_item.label_verbose, date) if planning.friday_pm
    end
  end

  def add_to_cache(label, date, abstract_amount = 0)
    cached = @cache[date]
    unless cached
      cached = DayOverview.new
      @cache[date] = cached
    end
    cached.add(label, abstract_amount)
  end

end
