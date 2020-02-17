module AccountingPostsHelper

  def blocking_worktimes(type)
    worktimes = @accounting_post.worktimes.includes(:employee)

    case type
    when :description then worktimes.where(description: '')
    when :ticket      then worktimes.where(ticket: '')
    when :absolute    then worktimes.where(report_type: :absolute_day)
    end
  end

  def blocking_alert(f, worktimes)
    f.labeled_static_text(
      blocking_list(worktimes),
      caption: blocking_title(worktimes)
    )
  end

  private

  def worktime_counts(worktimes)
    worktimes.group(:employee_id).count
  end

  def blocking_title(worktimes)
    "#{worktimes.count} blockierende Buchungen:"
  end

  def blocking_list(worktimes)
    worktime_counts(worktimes).collect do |k, v|
      employee = Employee.find(k)
      "#{employee.firstname} #{employee.lastname}: #{v} Buchungen"
    end.join(", ")
  end
end
