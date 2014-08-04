# encoding: utf-8

class VacationGraph

  include ActionView::Helpers::NumberHelper

  # TODO separate view helpers from this class
  include GraphHelper

  attr_reader :period, :day

  UNPAID_ABSENCE = Absence.new name: 'Unbezahlter Urlaub'
  UNPAID_ABSENCE.id = 0


  def initialize(period = nil)
    period ||= Period.current_year
    @actual_period = period
    @period = extend_to_weeks period
    @todays_week = Period.week_for(Date.today).to_s

    @absences_eval = AbsencesEval.new

    @colorMap = AccountColorMapper.new
    @cache = {}
  end

  def each_employee
    @absences_eval.divisions(period).each do |empl|
      @absences_eval.set_division_id empl.id
      # trade some memory for speed
      @absencetimes = @absences_eval.times(period).
                                     reorder('work_date, from_start_time, employee_id, absence_id').
                                     includes(:absence).
                                     references(:absence).
                                     where('NOT absences.private AND (report_type = ? OR report_type = ? OR report_type = ?)',
                                           StartStopType::INSTANCE.key,
                                           HoursDayType::INSTANCE.key,
                                           HoursWeekType::INSTANCE.key)
      @monthly_absencetimes = @absences_eval.times(period).
                                             reorder('work_date, from_start_time, employee_id, absence_id').
                                             includes(:absence).
                                             references(:absence).
                                             where('NOT absences.private AND (report_type = ?)',
                                                   HoursMonthType::INSTANCE.key)
      @unpaid_absences = empl.statistics.employments_during(period).select { |e| e.percent == 0 }
      @unpaid_absences.collect! { |e| Period.new(e.start_date, e.end_date ? e.end_date : period.endDate) }
      @index = 0
      @monthly_index = 0
      @unpaid_index = 0
      @month = nil
      yield empl
    end
  end

  def timebox
    times = Hash.new(0)
    absences = add_absences times, @current
    tooltip = create_tooltip(absences)
    absences = add_monthly_absences times
    tooltip += '<br />'.html_safe unless tooltip.empty?
    tooltip += create_tooltip(absences)
    tooltip += '<br />'.html_safe if !tooltip.empty? && !absences.empty?
    tooltip += add_unpaid_absences times

  	 max_absence = get_max_absence times
  	 return nil if max_absence.nil?

  	 hours = times[max_absence] / Settings.must_hours_per_day
  	 color = color_for(max_absence) if max_absence
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

  def accounts_legend(type = Absence)
    @colorMap.accounts_legend(type)
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

  def add_unpaid_absences(times)
    tooltip = ''.html_safe
    @unpaid_absences.each do |unpaid|
      @current.step do |date|
        if unpaid.include?(date) && date.wday > 0 && date.wday < 6
          times[UNPAID_ABSENCE] += Settings.must_hours_per_day
          tooltip += "#{I18n.l(date)}: #{Settings.must_hours_per_day}0 h #{UNPAID_ABSENCE.label}<br/>".html_safe
        end
      end
    end
    tooltip
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
      "#{I18n.l(time.work_date)}: #{time.time_string} #{ERB::Util.h(time.absence.label)}"
    end
    entries.join('<br/>').html_safe
  end

  def color_for(absence)
    @colorMap[absence]
  end

end
