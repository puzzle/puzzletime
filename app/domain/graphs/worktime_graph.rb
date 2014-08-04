# encoding: utf-8

class WorktimeGraph

  WORKTIME_ORDER = 'work_date, from_start_time, project_id, absence_id'
  WORKTIME_CONDITIONS = ['(worktimes.report_type = ? OR worktimes.report_type = ?)',
                         StartStopType::INSTANCE.key,
                         HoursDayType::INSTANCE.key]

  attr_reader :period, :employee

  def initialize(period, employee)
    @period = extend_to_weeks period
    @employee = employee

    @projects_eval = EmployeeWorkItemsEval.new(@employee.id)
    @absences_eval = EmployeeAbsencesEval.new(@employee.id)

    @colorMap = AccountColorMapper.new
    @weekly_boxes = {}
    @monthly_boxes = {}
  end

  def each_day
    set_period_boxes(@monthly_boxes, Period.month_for(@period.startDate), HoursMonthType::INSTANCE)
    @period.step do |day|
      @current = Period.day_for(day)
      compute_period_times day
      yield day
    end
  end

  def timeboxes
    # must_hours are Settings.must_hours_per_day unless employment > 100%
    must_hours = Holiday.musttime(@current.startDate) * must_hours_factor
    period_boxes = concat_period_boxes
    @total_hours = 0
    @boxes = []

    # fill ordertimes
    append_period_boxes period_boxes[:projects], must_hours
    append_account_boxes @projects_eval.times(@current).
                                        where(WORKTIME_CONDITIONS).
                                        reorder(WORKTIME_ORDER).
                                        includes(:project)

    # add absencetimes, payed ones first
    append_period_boxes period_boxes[:absences], must_hours
    append_account_boxes(@absences_eval.times(@current).
                                        joins('LEFT JOIN absences ON absences.id = absence_id').
                                        reorder('absences.payed DESC, work_date, from_start_time, absence_id').
                                        where(WORKTIME_CONDITIONS))

    # add must_hours limit
    insert_musthours_line must_hours

    @boxes
  end

  def accounts?(type)
    @colorMap.accounts? type
  end

  def accounts_legend(type)
    @colorMap.accounts_legend type
  end

  def must_hours_factor
    p = @current || @period
    employment = @employee.employment_at(p.startDate)
    employment ? [employment.percent_factor, 1.0].max : 1.0
  end

  private

  def compute_period_times(day)
    if day.wday == 1
      set_period_boxes(@weekly_boxes, Period.week_for(day), HoursWeekType::INSTANCE)
    end
    if day.mday == 1
      set_period_boxes(@monthly_boxes, Period.month_for(day), HoursMonthType::INSTANCE)
    end
  end

  def set_period_boxes(hash, period, report_type)
    hash[:projects] = get_period_boxes(@projects_eval, period, report_type)
    hash[:absences] = get_period_boxes(@absences_eval, period, report_type)
  end

  def get_period_boxes(evaluation, period, report_type)
    projects = evaluation.times(period).
                          where(report_type: report_type.key).
                          reorder(WORKTIME_ORDER)
	  # stretch by employment musttime if employment > 100%
    hours = period.musttime.to_f * must_hours_factor
    return [] if hours == 0
    projects.collect { |w| Timebox.new(w, color_for(w), Timebox.height_from_hours(w.hours / hours))  }
  end

  def concat_period_boxes
    period_boxes = {}
    @monthly_boxes.keys.each do |key|
      period_boxes[key] = @monthly_boxes[key] + @weekly_boxes[key]
    end
    period_boxes
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
      @boxes.push Timebox.new(w, color_for(w))
      @total_hours += w.hours
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
      limit = Timebox.height_from_hours(must_hours)
      @boxes.each_index do |i|
        sum += @boxes[i].height
        diff = sum - limit
        if diff > 0
          @boxes[i].height = @boxes[i].height - diff
          @boxes.insert(i + 1, Timebox.must_hours(must_hours))
          @boxes.insert(i + 2, Timebox.new(@boxes[i].worktime, @boxes[i].color, diff, @boxes[i].tooltip))
          break
        elsif diff == 0
          @boxes.insert(i + 1, Timebox.must_hours(must_hours))
          break
        end
      end
    end
  end

  def color_for(worktime)
    @colorMap[worktime.account]
  end

  def extend_to_weeks(period)
    Period.new Period.week_for(period.startDate).startDate,
               Period.week_for(period.endDate).endDate,
               period.label
  end

end
