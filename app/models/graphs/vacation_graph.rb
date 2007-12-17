class VacationGraph
  
  WORKTIME_OPTIONS = {:order => 'work_date, from_start_time, employee_id, absence_id',
                      :conditions => ['(report_type = ? OR report_type = ? OR report_type = ?)',
                                       StartStopType::INSTANCE.key, 
                                       HoursDayType::INSTANCE.key,
                                       HoursWeekType::INSTANCE.key] }
									   
  MONTHLY_OPTIONS = {:order => 'work_date, from_start_time, employee_id, absence_id',
				     :conditions => ['(report_type = ?)',
							   		 HoursMonthType::INSTANCE.key] }  
  
  attr_reader :period, :day
  
  
  def initialize(period = nil)
    period ||= Period.currentYear
    @actual_period = period
    @period = extend_to_weeks period
    
    @absences_eval = AbsencesEval.new
    
    @colorMap = Hash.new
    @cache = Cache.new(60, 3 * @period.length/7)
  end
  
  def each_employee
  	@absences_eval.divisions.each do |empl|
  	  @absences_eval.set_division_id empl.id
	    yield empl
  	end
  end
  
  def each_week
	  @period.startDate.step(@period.endDate, 7) do |day|
      @current = get_period_week(day)
      yield day
	  end
  end
     
  def timebox
  	times = Hash.new(0)
  	absences = add_absences times, @current
    tooltip = create_tooltip(absences)
  	absences = add_monthly_absences times
    tooltip += create_tooltip(absences)
  	
  	max_absence = get_max_absence times
  	return nil if max_absence.nil?
  	
  	hours = times[max_absence] / MUST_HOURS_PER_DAY
  	color = colorFor(max_absence) if max_absence
  	Timebox.new hours, color, tooltip 
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
  
  def accounts?(type)
    ! accounts(type).empty?
  end

  def accountsLegend(type)
    accounts = accounts(type).sort
    accounts.collect { |p| [p.label_verbose, @colorMap[p]] }
  end
  
private
  
  def add_absences(times, period = @current, options = WORKTIME_OPTIONS, factor = 1)
    absences = @absences_eval.times(period, options)
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
    add_absences(times, month, MONTHLY_OPTIONS, factor) if factor > 0   
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
    @colorMap[absence] ||= generateAbsenceColor(absence.id)
  end
  
  def generateAbsenceColor(id)
    srand id
    '#FF' + randomColor(190) + randomColor(10)
  end
  
  def randomColor(span = 170)
    lower = (255 - span) / 2
    (lower + rand(span)).to_s(16)
  end
  
  def accounts(type)
    @colorMap.keys.select { |key| key.is_a? type }
  end

  def extend_to_weeks(period)
    Period.new Period.weekFor(period.startDate).startDate,
               Period.weekFor(period.endDate).endDate,
               period.label
  end
  
  def get_period_month(date)  
    @cache.get(date.month) { Period.new(date.beginning_of_month, date.end_of_month)}
  end
  
  def get_period_week(from)
    get_period(from, from + 6)
  end
  
  def get_period(from, to)
    @cache.get([from, to]) { Period.new(from, to) }
  end
  
end