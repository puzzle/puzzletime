class AbsencePlanningGraph
  
  include PlanningHelper
  
  def initialize(absences, period)
    @period = period
    @cache = Hash.new
    
    absences.each do |absence|
      case absence.report_type
        when StartStopType
          add_start_stop_absence(absence)
        when HoursDayType
          add_day_absence(absence)
        when HoursWeekType
          add_weekly_absence(absence)
        when HoursMonthType
          add_month_absence(absence)
      end
    end
    
    @period.startDate.step(@period.endDate) do |day|
      if !Holiday.weekend?(day) && (Holiday.regularHoliday?(day) || Holiday.irregularHoliday?(day))
        add_to_cache("Feiertag", day)
      end
    end
  end

  def absence(date)
    @cache[date]    
  end

private
  def add_start_stop_absence(absence)
    add_to_cache(absence.timeString, absence.work_date, absence.hours*1)
  end
  
  def add_day_absence(absence)
    add_to_cache(absence.timeString, absence.work_date, absence.hours*1)
  end

  def add_weekly_absence(absence)
    date = absence.work_date
    5.times do
      add_to_cache(absence.timeString, date, absence.hours/5)
      date = date.next
    end
  end

  def add_month_absence(absence)
    dateFrom = Date.civil(absence.work_date.year, absence.work_date.month, 1)
    dateTo = Date.civil(dateFrom.year, dateFrom.month, -1)
    dateFrom.step(dateTo, 1) do |date|
      add_to_cache(absence.timeString, date, absence.hours/31)   # TODO: find number of work days in the month and divide by this number
    end
  end
  
  def add_to_cache(label, date, hours=0)
    cached = @cache[date]
    unless cached
      cached = DayOverview.new
      @cache[date] = cached
    end
    if hours==0
      cached.add(label)
    else
      cached.add(label, hours/8*10)
    end
  end

end
