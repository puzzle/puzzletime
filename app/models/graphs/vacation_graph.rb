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
    @period = extend_to_weeks period
    
    @absences_eval = AbsencesEval.new
    
    @colorMap = Hash.new
    @monthly_boxes = Hash.new
  end
  
  def each_employee
  	@absences_eval.divisions.each do |empl|
  	  @absences_eval.set_division_id empl.id
	  yield empl
  	end
  end
  
  def each_week
	@period.startDate.step(@period.endDate, 7) do |day|
      @current = Period.weekFor(day)
      yield day
	end
  end
     
  def timebox
	times = Hash.new(0)
	add_absences times, @current
	add_monthly_absences times
	
	max_absence = get_max_absence times
	return nil if max_absence.nil?
	
	hours = times[max_absence] / MUST_HOURS_PER_DAY
	color = colorFor(max_absence) if max_absence
    tooltip = create_tooltip times	
	Timebox.new hours, color, tooltip 
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
  end
    
  def add_monthly_absences(times)
    if @current.startDate.month == @current.endDate.month
	  add_monthly times, @current
    else
      add_monthly times, Period.retrieve(@current.startDate, @current.startDate.end_of_month)
	  add_monthly times, Period.retrieve(@current.endDate.beginning_of_month, @current.endDate)
    end
  end

  def add_monthly(times, period)
    month = Period.monthFor(period.startDate)
    factor = period.musttime.to_f / month.musttime.to_f
    add_absences(times, month, MONTHLY_OPTIONS, factor) if factor > 0   
  end

  def get_max_absence(times)
    times.invert[times.values.max]
  end

  def create_tooltip(times)
    entries = times.keys.collect do |absence| 
        "#{times[absence].round_with_precision(2)}h: #{absence.label}"
    end     
    entries.join("\n")
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
  
end