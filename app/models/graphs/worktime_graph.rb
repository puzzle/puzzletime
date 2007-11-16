class WorktimeGraph
  
  PIXEL_PER_HOUR = 4
  
  attr_reader :period, :employee, :day
  
  
  def initialize(period, employee)
    @period = extend_to_weeks period
    @employee = employee
    
    @projects_eval = EmployeeProjectsEval.new(@employee.id)
    @absences_eval = EmployeeAbsencesEval.new(@employee.id)
    @attendance_eval = AttendanceEval.new(@employee.id)
    
    @colorMap = Hash.new
  end
  
  
  def each_day
    @period.step { |day|
      @current = Period.dayFor(day)
      yield day
    }
  end
  
  
  
  def timeboxes
    projects = @projects_eval.times(@current)
    attendance_hours = @attendance_eval.sum_total_times(@current)
    
    total_hours = 0
    boxes = Array.new
    # fill projecttimes
    print "fill projects"
    projects.each do |w| 
      boxes.push Timebox.new(heightFor(w.hours), colorFor(w), tooltipFor(w))
      total_hours += w.hours
    end
    
    # add attendance difference
    print "add attendance"
    diff = attendance_hours - total_hours
    if diff > 0
      total_hours += diff
      boxes.push Timebox.attendance_pos(heightFor(diff))
    elsif diff < 0
      # replace with removing corresponding projecttime algorithm
      diff_height = heightFor(-diff)
      boxes.reverse_each do |b|
        diff_height -= b.height
        if diff_height < 0
          b.height = -diff_height
          break
        else
          boxes.pop
        end
      end
      boxes.push Timebox.attendance_neg(heightFor(-diff))
    end
    
    # add absencetimes, payed ones first
    print "add absences"
    absences = @absences_eval.times(@current, 
                    :joins => 'LEFT JOIN absences ON absences.id = absence_id',
                    :order => "absences.payed DESC, work_date, from_start_time, absence_id")
    absences.each do |w|
      boxes.push Timebox.new(heightFor(w.hours), colorFor(w), tooltipFor(w))
      total_hours += w.hours
    end
    
    # add must_hours limit
    print "add must hours"
    must_hours = Holiday.musttime(@current.startDate)
    if total_hours < must_hours
      boxes.push Timebox.blank(heightFor(must_hours - total_hours))
      boxes.push Timebox.must_hours
    elsif total_hours == must_hours
      boxes.push Timebox.must_hours
    else
      sum = 0
      limit = heightFor(must_hours)
      boxes.each_index do |i|
        sum += boxes[i].height
        diff = sum - limit
        if diff > 0
          boxes[i].height = boxes[i].height - diff
          boxes.insert(i+1, Timebox.must_hours)
          boxes.insert(i+2, Timebox.new(diff, boxes[i].color, boxes[i].tooltip))
          break
        elsif diff == 0
          boxes.insert(i+1, Timebox.must_hours)
          break
        end
      end
    end
    
    boxes
  end

  
  def heightFor(hours)
    hours * PIXEL_PER_HOUR
  end
  
  def colorFor(worktime)
    @colorMap[worktime.account] ||= generateColor(worktime.absence? ? 1 : 3, worktime.account_id)
  end
  
  def generateColor(chanel, seed)
    srand seed
    val = (50 + rand(150)).to_s(16)
    '#' + [1,2,3].collect{ |c| c == chanel ? 'FF' : val }.join
  end
  
  def tooltipFor(worktime)
    worktime.timeString + ': ' + worktime.account.label
  end

  
private

  def extend_to_weeks(period)
    Period.new Period.weekFor(period.startDate).startDate,
               Period.weekFor(period.endDate).endDate,
               period.label
  end
  
end