# encoding: utf-8

module WorktimeHelper
  def worktime_account(worktime)
    worktime.account.label_verbose if worktime.account
  end

  def worktime_description(worktime)
    [worktime.ticket.presence, worktime.description.presence].compact.join(' - ')
  end

  def work_item_option(item)
    if item
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
  end

  def overview_day_class(_worktimes, day)
    if day == Time.zone.today
      'today'
    elsif Holiday.holiday?(day)
      'holiday'
    elsif day < Time.zone.today && sum_hours(day) <= 0
      'missing'
    end
  end

  def time_range(worktime)
    result = '&nbsp;'
    if worktime.from_start_time.present?
      result = "#{format_time(worktime.from_start_time)} - "
      if worktime.to_end_time.present?
        result += format_time(worktime.to_end_time)
      end
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
      @daily_worktimes[day] ? @daily_worktimes[day].map(&:hours).sum : 0
    else
      @worktimes.map(&:hours).sum
    end
  end
end
