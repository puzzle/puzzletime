# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class VacationGraph

  attr_reader :period, :day

  UNPAID_ABSENCE = Absence.new name: 'Unbezahlter Urlaub'
  UNPAID_ABSENCE.id = 0


  def initialize(period = nil)
    period ||= Period.current_year
    @actual_period = period
    @period = period.extend_to_weeks
    @todays_week = Period.week_for(Time.zone.today).to_s

    @absences_eval = AbsencesEval.new

    @color_map = AccountColorMapper.new
  end

  def each_employee
    Employee.employed_ones(@actual_period).each do |empl|
      @absences_eval.set_division_id empl.id
      # trade some memory for speed
      @absencetimes = @absences_eval.times(period).
                      reorder('work_date, from_start_time, employee_id, absence_id').
                      includes(:absence).
                      references(:absence).
                      where('report_type = ? OR report_type = ? OR report_type = ?',
                            StartStopType::INSTANCE.key,
                            HoursDayType::INSTANCE.key,
                            HoursWeekType::INSTANCE.key)
      @monthly_absencetimes = @absences_eval.times(period).
                              reorder('work_date, from_start_time, employee_id, absence_id').
                              includes(:absence).
                              references(:absence).
                              where('report_type = ?',
                                    HoursMonthType::INSTANCE.key)
      @unpaid_absences = empl.statistics.employments_during(period).select { |e| e.percent.zero? }
      @unpaid_absences.collect! { |e| Period.new(e.start_date, e.end_date ? e.end_date : period.end_date) }
      @index = 0
      @monthly_index = 0
      @unpaid_index = 0
      @month = nil
      yield empl
    end
  end

  def each_day
    @period.step do |day|
      @current = get_period_week(day)
      yield day
    end
  end

  def each_week
    @period.step(7) do |week|
      @current = get_period_week(week)
      yield week
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

    return nil if times.blank?
    max_absence = get_max_absence(times)

    hours = times.values.sum / WorkingCondition.value_at(@current.start_date, :must_hours_per_day)
    color = color_for(max_absence)
    Timebox.new nil, color, hours, tooltip
  end

  def employee
    @absences_eval.division
  end

  def previous_left_vacations
    employee.statistics.remaining_vacations(@actual_period.start_date - 1).round(1)
  end

  def following_left_vacations
    employee.statistics.remaining_vacations(@actual_period.end_date).round(1)
  end

  def granted_vacations
    employee.statistics.total_vacations(@actual_period).round(1)
  end

  def used_vacations
    employee.statistics.used_vacations(@actual_period).round(1)
  end

  def accounts?(type = Absence)
    @color_map.accounts?(type)
  end

  def accounts_legend(type = Absence)
    @color_map.accounts_legend(type)
  end

  def current_week?
    @current.to_s == @todays_week
  end

  private

  def add_absences(times, period = @current, monthly = false, factor = 1)
    absences = monthly ? monthly_absences_during(period) : absences_during(period)
    absences.each do |time|
      times[time.absence] += time.hours * factor
    end
    absences
  end

  def add_monthly_absences(times)
    if @current.start_date.month == @current.end_date.month
      add_monthly times, @current
    else
      part1 = add_monthly times, get_period(@current.start_date, @current.start_date.end_of_month)
      part2 = add_monthly times, get_period(@current.end_date.beginning_of_month, @current.end_date)
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
          must = WorkingCondition.value_at(date, :must_hours_per_day)
          times[UNPAID_ABSENCE] += must
          tooltip += "#{I18n.l(date)}: #{must} h #{UNPAID_ABSENCE.label}<br/>".html_safe
        end
      end
    end
    tooltip
  end

  def add_monthly(times, period)
    month = get_period_month(period.start_date)
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
    return [] if index >= collection.size || collection[index].work_date > period.end_date
    list = []
    while index < collection.size && collection[index].work_date <= period.end_date
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
      "#{I18n.l(time.work_date)}: #{time.time_string} Abwesenheit"
    end
    entries.join('<br/>').html_safe
  end

  def color_for(absence)
    # @color_map[absence]
    if absence == UNPAID_ABSENCE
      '#cc9557'
    else
      '#cc2767'
    end
  end

  def get_period_week(from)
    get_period(from, from + 6)
  end

  def get_period_month(date)
    get_set_cache(date.month) { Period.new(date.beginning_of_month, date.end_of_month) }
  end

  def get_period(from, to)
    get_set_cache([from, to]) { Period.new(from, to) }
  end

  def get_set_cache(key)
    val = cache[key]
    if val.nil?
      val = yield
      cache[key] = val
    end
    val
  end

  def cache
    @cache ||= {}
  end

end
