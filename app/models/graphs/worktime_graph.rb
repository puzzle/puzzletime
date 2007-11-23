class WorktimeGraph
  
  PIXEL_PER_HOUR = 6.0
  WORKTIME_OPTIONS = {:order => 'work_date, from_start_time, project_id, absence_id',
                      :conditions => ['(report_type = ? OR report_type = ?)',
                                       StartStopType::INSTANCE.key, 
                                       HoursDayType::INSTANCE.key] }
  
  
  attr_reader :period, :employee, :day
  
  
  def initialize(period, employee)
    @period = extend_to_weeks period
    @employee = employee
    
    @projects_eval = EmployeeProjectsEval.new(@employee.id)
    @absences_eval = EmployeeAbsencesEval.new(@employee.id)
    @attendance_eval = AttendanceEval.new(@employee.id)
    
    @colorMap = Hash.new
    @weekly_boxes = Hash.new
    @monthly_boxes = Hash.new
  end
  
  def each_day
    set_period_boxes(@monthly_boxes, Period.monthFor(@period.startDate), HoursMonthType::INSTANCE)   
    @period.step { |day|
      @current = Period.dayFor(day)
      compute_period_times day
      yield day
    }
  end
     
  def timeboxes
    must_hours = Holiday.musttime(@current.startDate)
    period_boxes = concat_period_boxes    
    @total_hours = 0
    @boxes = Array.new
    
    # fill projecttimes
    append_period_boxes period_boxes[:projects], must_hours
    append_account_boxes @projects_eval.times(@current, WORKTIME_OPTIONS)

    # add attendance difference
    attendance_hours = compute_attendance_hours(must_hours, period_boxes[:attendance])
    insert_attendance_diff attendance_hours
    
    # add absencetimes, payed ones first
    append_period_boxes period_boxes[:absences], must_hours
    append_account_boxes( @absences_eval.times(@current, 
                          :joins => 'LEFT JOIN absences ON absences.id = absence_id',
                          :order => "absences.payed DESC, work_date, from_start_time, absence_id",
                          :conditions => WORKTIME_OPTIONS[:conditions].clone) )

    # add must_hours limit
    insert_musthours_line must_hours
   
    @boxes
  end
  
  def accounts?(type)
    ! accounts(type).empty?
  end

  def accountsLegend(type)
    accounts = accounts(type).sort
    accounts.collect { |p| [p.label_verbose, @colorMap[p]] }
  end
  
private
  
  def compute_period_times(day)
    if day.wday == 1
      set_period_boxes(@weekly_boxes, Period.weekFor(day), HoursWeekType::INSTANCE)   
    end
    if day.mday == 1
      set_period_boxes(@monthly_boxes, Period.monthFor(day), HoursMonthType::INSTANCE)            
    end
  end
  
  def set_period_boxes(hash, period, report_type)
    hash[:projects] = get_period_boxes( @projects_eval, period, report_type )
    hash[:absences] = get_period_boxes( @absences_eval, period, report_type )
    hash[:attendance] = get_period_boxes( @attendance_eval, period, report_type )
  end
  
  def get_period_boxes(evaluation, period, report_type)
    conditions = [ "report_type = ?", report_type.key]
    options = WORKTIME_OPTIONS.merge(:conditions => conditions)               
    projects = evaluation.times(period, options) 
    hours = period.musttime.to_f
    return [] if hours == 0
    projects.collect { |w| Timebox.new(heightFor(w.hours/hours), colorFor(w), tooltipFor(w))  }
  end  
          
  def concat_period_boxes
    period_boxes = Hash.new
    @monthly_boxes.keys.each do |key|
      period_boxes[key] = @monthly_boxes[key] + @weekly_boxes[key]
    end
    period_boxes
  end
 
  def compute_attendance_hours(must_hours, period_boxes)
    attendance_hours = @attendance_eval.sum_total_times(@current, 
                          {:conditions => WORKTIME_OPTIONS[:conditions]})
    period_boxes.each do |box|
      attendance_hours += (box.height * must_hours) / PIXEL_PER_HOUR
    end
    attendance_hours
  end
  
  def append_period_boxes(period_boxes, must_hours)
    period_boxes.each do |b|
      box = b.clone
      box.stretch(must_hours)
      @boxes.push box
      @total_hours += box.height / PIXEL_PER_HOUR
    end
  end  
  
  def append_account_boxes(worktimes)
    worktimes.each do |w| 
      @boxes.push Timebox.new(heightFor(w.hours), colorFor(w), tooltipFor(w))
      @total_hours += w.hours
    end
  end

  def insert_attendance_diff(attendance_hours)
    diff = attendance_hours - @total_hours
    if diff > 0.01
      @total_hours += diff
      @boxes.push Timebox.attendance_pos(heightFor(diff))
    elsif diff < 0.01
      # replace with removing corresponding projecttime algorithm
      diff_height = heightFor(-diff)
      @boxes.reverse_each do |b|
        diff_height -= b.height
        if diff_height < 0
          b.height = -diff_height
          break
        else
          @boxes.pop
        end
      end
      @boxes.push Timebox.attendance_neg(heightFor(-diff))
    end
  end
  
  def insert_musthours_line(must_hours)
    if @total_hours < must_hours
      @boxes.push Timebox.blank(heightFor(must_hours - @total_hours))
      @boxes.push Timebox.must_hours
    elsif @total_hours == must_hours
      @boxes.push Timebox.must_hours
    else
      sum = 0
      limit = heightFor(must_hours)
      @boxes.each_index do |i|
        sum += @boxes[i].height
        diff = sum - limit
        if diff > 0
          @boxes[i].height = @boxes[i].height - diff
          @boxes.insert(i+1, Timebox.must_hours)
          @boxes.insert(i+2, Timebox.new(diff, @boxes[i].color, @boxes[i].tooltip))
          break
        elsif diff == 0
          @boxes.insert(i+1, Timebox.must_hours)
          break
        end
      end
    end
  end
  
  def heightFor(hours)
    hours * PIXEL_PER_HOUR
  end
  
  def colorFor(worktime)
    @colorMap[worktime.account] ||= generateColor(worktime)
  end
  
  def generateColor(worktime)
    return Timebox::ATTENDANCE_POS_COLOR unless worktime.account_id
    worktime.absence? ? 
        generateAbsenceColor(worktime.absence_id) :
        generateProjectColor(worktime.project_id)
  end
  
  def generateAbsenceColor(id)
    srand id
    val = randomColor
    '#FF' + val + val
  end
  
  def generateProjectColor(id)
    srand id
    '#' + randomColor + randomColor + 'FF'
  end
  
  def randomColor
    (50 + rand(150)).to_s(16)
  end
  
  def tooltipFor(worktime)
    worktime.timeString + ': ' + (worktime.account ? worktime.account.label : 'Anwesenheit')
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