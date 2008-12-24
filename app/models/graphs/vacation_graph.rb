class VacationGraph
  
  attr_reader :period, :day
  
  
  def initialize(period = nil)
    period ||= Period.currentYear
    @actual_period = period
    @period = extend_to_weeks period
    @todays_week = Period.weekFor(Date.today).to_s
    
    @absences_eval = AbsencesEval.new
    
    @colorMap = AccountColorMapper.new
    @cache = Hash.new
  end
  
  def each_employee
  	@absences_eval.divisions(period).each do |empl|
  	  @absences_eval.set_division_id empl.id
      # trade some memory for speed
      @absencetimes = @absences_eval.times(period, 
                        {:order      => 'work_date, from_start_time, employee_id, absence_id',
                         :include    => 'absence',
                         :conditions => ['NOT absences.private AND (report_type = ? OR report_type = ? OR report_type = ?)',
                                         StartStopType::INSTANCE.key, 
                                         HoursDayType::INSTANCE.key,
                                         HoursWeekType::INSTANCE.key] })
      @monthly_absencetimes = @absences_eval.times(period,
                        {:order      => 'work_date, from_start_time, employee_id, absence_id',
                         :include    => 'absence',
                         :conditions => ['NOT absences.private AND (report_type = ?)', HoursMonthType::INSTANCE.key] }  )
      @index = 0
      @monthly_index = 0
      @month = nil
	    yield empl
  	end
  end
  
  def each_week
	  @period.startDate.step(@period.endDate, 7) do |day|
      @current = get_period_week(day)
      yield day
	  end
	end
 
  def is_current_week
    @current.to_s == @todays_week
  end
     
  def timebox
  	times = Hash.new(0)
  	absences = add_absences times, @current
    tooltip = create_tooltip(absences)
  	absences = add_monthly_absences times
    tooltip += '<br />' if not tooltip.empty?
    tooltip += create_tooltip(absences)
  	
  	max_absence = get_max_absence times
  	return nil if max_absence.nil?
  	
  	hours = times[max_absence] / MUST_HOURS_PER_DAY
  	color = colorFor(max_absence) if max_absence
  	Timebox.new nil, color, hours, tooltip 
  end
 
  def employee
    @absences_eval.division
  end
 
  def previous_left_vacations
    employee.statistics.remaining_vacations(@actual_period.startDate - 1).round(1)
  end
  
  def following_left_vacations
    employee.statistics.remaining_vacations(@actual_period.endDate + 1).round(1)
  end
  
  def granted_vacations
    employee.statistics.total_vacations(@actual_period).round(1)
  end
  
  def used_vacations
    employee.statistics.used_vacations(@actual_period).round(1)
  end
  
  def accounts?(type = Absence)
    @colorMap.accounts?(type)
  end

  def accountsLegend(type = Absence)
    @colorMap.accountsLegend(type)
  end
  
private
  
  def add_absences(times, period = @current, monthly = false, factor = 1)
    absences = monthly ?  monthly_absences_during(period) : absences_during(period)
    absences.each do |time|
      times[time.absence] += time.hours * factor 
    end     
    absences
  end
    
  def add_monthly_absences(times)
    if @current.startDate.month == @current.endDate.month
	    add_monthly times, @current
    else
      part1 = add_monthly times, get_period(@current.startDate, @current.startDate.end_of_month)
	    part2 = add_monthly times, get_period(@current.endDate.beginning_of_month, @current.endDate)
      part1 ||= []
      part2 ||= []
      part1.concat part2
    end
  end

  def add_monthly(times, period)
    month = get_period_month(period.startDate)
    factor = period.musttime.to_f / month.musttime.to_f
    add_absences(times, month, true, factor) if factor > 0   
  end
  
  def absences_during(period)
    list = iterated_absences(period, @absencetimes, @index)
    @index += list.size
    list
  end
  
  def monthly_absences_during(period)
    return @monthly_list if @month == period
    @monthly_list = iterated_absences(period, @monthly_absencetimes, @monthly_index)
    @month = period
    @monthly_index += @monthly_list.size
    @monthly_list
  end
  
  def iterated_absences(period, collection, index)
    return [] if index >= collection.size || collection[index].work_date > period.endDate
    list = []
    while index < collection.size && collection[index].work_date <= period.endDate
      list.push collection[index]
      index += 1
    end
    list
  end

  def get_max_absence(times)
    times.invert[times.values.max]
  end

  def create_tooltip(absences)
    entries = absences.collect do |time| 
        "#{time.work_date.strftime(DATE_FORMAT)}: #{time.timeString} #{time.absence.label}"
    end     
    entries.join("<br/>")
  end

  def colorFor(absence)
    @colorMap[absence]
  end
  
  def extend_to_weeks(period)
    Period.new Period.weekFor(period.startDate).startDate,
               Period.weekFor(period.endDate).endDate,
               period.label
  end
  
  def get_period_month(date)
    get_set_cache(date.month) { Period.new(date.beginning_of_month, date.end_of_month) }
  end
  
  def get_period_week(from)
    get_period(from, from + 6)
  end
  
  def get_period(from, to)
    get_set_cache([from, to]) { Period.new(from, to) }
  end
  
  def get_set_cache(key)
    val = @cache[key]
    if val.nil?
      val = yield
      @cache[key] = val
    end
    val
  end
  
end