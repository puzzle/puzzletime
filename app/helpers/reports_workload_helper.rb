module ReportsWorkloadHelper
  def format_workload_hours(value)
    content_tag(:span, format_number(value, 0), title: value)
  end

  def format_workload_worktime_balance(value)
    content_tag(:span, format_number(value, 0), title: value, class: workload_worktime_balance_class(value))
  end

  def format_workload_billability(value)
    content_tag(:span, value.round, title: value, class: workload_worktime_billability_class(value))
  end

  def format_workload_load(value)
    content_tag(:span, value.round, title: value, class: workload_worktime_load_class(value))
  end

  def workload_hours_url(ordertime_entry, entry, report)
    url_for(category_id: ordertime_entry.id,
            evaluation: "employeesubworkitems#{entry.employee.id}",
            start_date: report.period.start_date,
            end_date: report.period.end_date,
            controller: 'evaluator',
            action: 'details')
  end

  def workload_absences_url(employee_id, report)
    url_for(category_id: employee_id,
            evaluation: 'employeeabsences',
            start_date: report.period.start_date,
            end_date: report.period.end_date,
            controller: 'evaluator',
            action: 'details')
  end

  private

  def workload_worktime_balance_class(value)
    config = Settings.reports.workload.worktime_balance
    if value < config.lower_limit
      'red'
    end
  end

  def workload_worktime_billability_class(value)
    config = Settings.reports.workload.billability
    if value >= config.green
      'green'
    elsif value >= config.orange
      'orange'
    else
      'red'
    end
  end

  def workload_worktime_load_class(value)
    config = Settings.reports.workload.load
    if value >= config.green
      'green'
    elsif value >= config.orange
      'orange'
    else
      'red'
    end
  end
end
