# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module WorktimeHelper
  def worktime_account(worktime)
    worktime.account&.label_verbose
  end

  def worktime_description(worktime)
    [worktime.ticket.presence, worktime.description.presence].compact.join(' - ')
  end

  def work_item_option(item)
    return unless item

    json = { id: item.id,
             name: item.name,
             path_shortnames: item.path_shortnames,
             description: item.description }
    content_tag(:option,
                item.label_verbose,
                value: item.id,
                selected: true,
                data: { data: json.to_json })
  end

  def overview_day_class(_worktimes, day)
    if day == Time.zone.today
      'today'
    elsif Holiday.non_working_day?(day)
      'holiday'
    elsif day < Time.zone.today && sum_hours(day) <= 0
      'missing'
    end
  end

  def time_range(worktime)
    result = '&nbsp;'
    if worktime.from_start_time.present?
      result = "#{format_time(worktime.from_start_time)} - "
      result += format_time(worktime.to_end_time) if worktime.to_end_time.present?
    end
    result.html_safe
  end

  def week_number(date)
    date.strftime('%V').to_i if date
  end

  def monthly_worktime
    safe_join([
                format_hour(@monthly_worktime),
                ' (',
                format_hour(@pending_worktime),
                ' verbleibend)'
              ])
  end

  # sum worktime hours for a given date. if no date is given, sum all worktime hours
  def sum_hours(day = nil)
    if day
      @daily_worktimes[day] ? @daily_worktimes[day].sum(&:hours) : 0
    else
      @worktimes.sum(&:hours)
    end
  end
end
