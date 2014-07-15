# encoding: utf-8

module WorktimeHelper

  def worktime_account(worktime)
    worktime.account.label_verbose if worktime.account
  end

  def worktime_description(worktime)
    description = worktime.description
    description.insert(0, "#{worktime.ticket} - ") if worktime.ticket.present?
    description
  end

  def overview_day_class(worktimes, day)
    if day == Date.today
      'today'
    elsif Holiday.holiday?(day)
      'holiday'
    elsif day < Date.today && sum_daily_worktimes(worktimes, day) <= 0
      'missing'
    end
  end

  def time_range(worktime)
    result = "&nbsp;"
    if worktime.from_start_time.present?
      result = "#{format_time(worktime.from_start_time)} - "
      if worktime.to_end_time.present?
        result += format_time(worktime.to_end_time)
      end
    end
    result.html_safe
  end
  
  def week_number(date)
    date.strftime("%U").to_i if date
  end

  def monthly_worktime
    "#{format_hour(@monthly_worktime)} (#{format_hour(@pending_worktime)} verbleibend)"
  end

  def daily_worktimes(worktimes, day)
    worktimes.select{|worktime| worktime.work_date == day}
  end


  def sum_daily_worktimes(worktimes, day)
    sum_total_worktimes(daily_worktimes(worktimes, day))
  end

  def sum_total_worktimes(worktimes)
    worktimes.map(&:hours).inject(0, :+)
  end

end
