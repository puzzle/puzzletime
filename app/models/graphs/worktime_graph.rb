class WorktimeGraph
  
  WORKTIME_OPTIONS = {:order => 'work_date, from_start_time, project_id, absence_id',
                      :conditions => ['(report_type = ? OR report_type = ?)',
                                       StartStopType::INSTANCE.key, 
                                       HoursDayType::INSTANCE.key] }
 
  attr_reader :period, :employee
  
  def initialize(period, employee)
    @period = extend_to_weeks period
    @employee = employee
    
    @projects_eval = EmployeeProjectsEval.new(@employee.id, true)
    @absences_eval = EmployeeAbsencesEval.new(@employee.id)
    @attendance_eval = AttendanceEval.new(@employee.id)
    
    @colorMap = AccountColorMapper.new
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
    # must_hours are MUST_HOURS_PER_DAY unless employment > 100%
    must_hours = Holiday.musttime(@current.startDate) * must_hours_factor
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
    @colorMap.accounts? type
  end

  def accountsLegend(type)
    @colorMap.accountsLegend type
  end
  
  def must_hours_factor
    p = @current || @period
    employment = @employee.employment_at(p.startDate)
    employment ? [employment.percentFactor, 1.0].max : 1.0
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
	  # stretch by employment musttime if employment > 100%
    hours = period.musttime.to_f * must_hours_factor
    return [] if hours == 0
    projects.collect { |w| Timebox.new(w, colorFor(w), Timebox::height_from_hours(w.hours/hours))  }
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
      attendance_hours += (box.height * must_hours) / Timebox::PIXEL_PER_HOUR
    end
    attendance_hours
  end
  
  def append_period_boxes(period_boxes, must_hours)
    period_boxes.each do |b|
      box = b.clone
      box.stretch(must_hours)
      @boxes.push box
      @total_hours += box.height / Timebox::PIXEL_PER_HOUR
    end
  end  
  
  def append_account_boxes(worktimes)
    worktimes.each do |w| 
      @boxes.push Timebox.new(w, colorFor(w))
      @total_hours += w.hours
    end
  end

  def insert_attendance_diff(attendance_hours)
    diff = attendance_hours - @total_hours
    if diff > 0.01
      @total_hours += diff
      attendance = @attendance_eval.times(@current, {:conditions => WORKTIME_OPTIONS[:conditions]}).first
      @boxes.push Timebox.attendance_pos(attendance, diff)
    elsif diff < -0.01
      # replace with removing corresponding projecttime algorithm
      diff_height = Timebox::height_from_hours(-diff)
      @boxes.reverse_each do |b|
        diff_height -= b.height
        if diff_height < 0
          b.height = -diff_height
          break
        else
          @boxes.pop
        end
      end
      attendance = Attendancetime.new(:employee_id => @employee.id, 
                                  :work_date => @current.startDate, 
                                  :hours => diff,
                                  :report_type => HoursDayType::INSTANCE)
      @boxes.push Timebox.attendance_neg(attendance, -diff)
    end
  end
  
  def insert_musthours_line(must_hours)
    if @total_hours < must_hours
      @boxes.push Timebox.blank(must_hours - @total_hours)
      @boxes.push Timebox.must_hours(must_hours)
    elsif @total_hours == must_hours
      @boxes.push Timebox.must_hours(must_hours)
    else
      sum = 0
      limit = Timebox::height_from_hours(must_hours)
      @boxes.each_index do |i|
        sum += @boxes[i].height
        diff = sum - limit
        if diff > 0
          @boxes[i].height = @boxes[i].height - diff
          @boxes.insert(i+1, Timebox.must_hours(must_hours))
          @boxes.insert(i+2, Timebox.new(@boxes[i].worktime, @boxes[i].color, diff, @boxes[i].tooltip))
          break
        elsif diff == 0
          @boxes.insert(i+1, Timebox.must_hours(must_hours))
          break
        end
      end
    end
  end
  
  def colorFor(worktime)
    @colorMap[worktime.account]
  end

  def extend_to_weeks(period)
    Period.new Period.weekFor(period.startDate).startDate,
               Period.weekFor(period.endDate).endDate,
               period.label
  end
  
end