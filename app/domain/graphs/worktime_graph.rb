# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Graphs
  class WorktimeGraph
    WORKTIME_ORDER = 'work_date, from_start_time, work_item_id, absence_id'
    WORKTIME_CONDITIONS = [
      '(worktimes.report_type = ? OR worktimes.report_type = ?)',
      ReportType::StartStopType::INSTANCE.key,
      ReportType::HoursDayType::INSTANCE.key
    ].freeze

    attr_reader :period, :employee

    def initialize(period, employee)
      @period = period.extend_to_weeks
      @employee = employee

      @work_items_eval = Evaluations::EmployeeWorkItemsEval.new(@employee.id)
      @absences_eval = Evaluations::EmployeeAbsencesEval.new(@employee.id)

      @color_map = Graphs::AccountColorMapper.new
      @weekly_boxes = {}
      @monthly_boxes = {}
    end

    def each_day
      set_period_boxes(@monthly_boxes, Period.month_for(@period.start_date), ReportType::HoursMonthType::INSTANCE)
      @period.step do |day|
        @current = Period.day_for(day)
        compute_period_times day
        yield day
      end
    end

    def timeboxes
      # must_hours are must_hours_per_day unless employment > 100%
      must_hours = Holiday.musttime(@current.start_date) * must_hours_factor
      period_boxes = concat_period_boxes
      @total_hours = 0
      @boxes = []

      # fill ordertimes
      append_period_boxes period_boxes[:work_items], must_hours
      append_account_boxes @work_items_eval.times(@current)
                                           .where(WORKTIME_CONDITIONS)
                                           .reorder(WORKTIME_ORDER)
                                           .includes(:work_item, :invoice)

      # add absencetimes, payed ones first
      append_period_boxes period_boxes[:absences], must_hours
      append_account_boxes(@absences_eval.times(@current)
                                          .joins('LEFT JOIN absences ON absences.id = absence_id')
                                          .reorder('absences.payed DESC, work_date, from_start_time, absence_id')
                                          .where(WORKTIME_CONDITIONS))

      # add must_hours limit
      insert_musthours_line must_hours

      @boxes
    end

    delegate :accounts?, to: :@color_map

    delegate :accounts_legend, to: :@color_map

    def must_hours_factor
      p = @current || @period
      employment = @employee.employment_at(p.start_date)
      employment ? [employment.percent_factor, 1.0].max : 1.0
    end

    private

    def compute_period_times(day)
      set_period_boxes(@weekly_boxes, Period.week_for(day), ReportType::HoursWeekType::INSTANCE) if day.wday == 1
      return unless day.mday == 1

      set_period_boxes(@monthly_boxes, Period.month_for(day), ReportType::HoursMonthType::INSTANCE)
    end

    def set_period_boxes(hash, period, report_type)
      hash[:work_items] = get_period_boxes(@work_items_eval, period, report_type)
      hash[:absences] = get_period_boxes(@absences_eval, period, report_type)
    end

    def get_period_boxes(evaluation, period, report_type)
      work_items = evaluation.times(period)
                             .where(report_type: report_type.key)
                             .reorder(WORKTIME_ORDER)
      # stretch by employment musttime if employment > 100%
      hours = period.musttime.to_f * must_hours_factor
      return [] if hours.zero?

      work_items.collect do |w|
        Graphs::Timebox.new(w, color_for(w), Graphs::Timebox.height_from_hours(w.hours / hours))
      end
    end

    def concat_period_boxes
      period_boxes = {}
      @monthly_boxes.each_key do |key|
        period_boxes[key] = @monthly_boxes[key] + @weekly_boxes[key]
      end
      period_boxes
    end

    def append_period_boxes(period_boxes, must_hours)
      period_boxes.each do |b|
        box = b.clone
        box.stretch(must_hours)
        @boxes.push box
        @total_hours += box.height / Graphs::Timebox::PIXEL_PER_HOUR
      end
    end

    def append_account_boxes(worktimes)
      worktimes.each do |w|
        @boxes.push Graphs::Timebox.new(w, color_for(w))
        @total_hours += w.hours
      end
    end

    def insert_musthours_line(must_hours)
      if @total_hours < must_hours
        @boxes.push Graphs::Timebox.blank(must_hours - @total_hours)
        @boxes.push Graphs::Timebox.must_hours(must_hours)
      elsif @total_hours == must_hours
        @boxes.push Graphs::Timebox.must_hours(must_hours)
      else
        sum = 0
        limit = Timebox.height_from_hours(must_hours)
        @boxes.each_index do |i|
          sum += @boxes[i].height
          diff = sum - limit
          if diff.positive?
            @boxes[i].height = @boxes[i].height - diff
            @boxes.insert(i + 1, Graphs::Timebox.must_hours(must_hours))
            @boxes.insert(i + 2, Graphs::Timebox.new(@boxes[i].worktime, @boxes[i].color, diff, @boxes[i].tooltip))
            break
          elsif diff.zero?
            @boxes.insert(i + 1, Graphs::Timebox.must_hours(must_hours))
            break
          end
        end
      end
    end

    def color_for(worktime)
      @color_map[worktime.account]
    end
  end
end
