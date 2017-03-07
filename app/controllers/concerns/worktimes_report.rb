
module WorktimesReport
  extend ActiveSupport::Concern

  private

  def render_report(times)
    @worktimes = times.includes(:employee)
    @ticket_view = params[:combine_on] &&
      (params[:combine] == 'ticket' || params[:combine] == 'ticket_employee')
    combine_times if params[:combine_on] && params[:combine] == 'time'
    combine_tickets if @ticket_view
    render template: 'worktimes_report/report', layout: 'print'
  end

  def combine_times
    combined_map = {}
    combined_times = []
    @worktimes.each do |time|
      if time.report_type.is_a?(StartStopType) && params[:start_stop]
        combined_times.push time
      else
        combine_time(combined_map, combined_times, time)
      end
    end
    @worktimes = combined_times
  end

  # builds a hash which contains all information needed by the report grouped by ticket
  def combine_tickets
    @tickets = {}
    @employees = {}

    @worktimes.group_by(&:ticket).each do |ticket, worktimes|
      if @tickets[ticket].nil?
        @tickets[ticket] = { n_entries: 0,
                             sum: 0,
                             employees: {},
                             date: Array.new(2),
                             descriptions: [] }
      end

      worktimes.each { |worktime| combine_ticket(@tickets[ticket], @employees, worktime) }
    end
  end

  def combine_time(combined_map, combined_times, time)
    key = "#{time.date_string}$#{time.employee.shortname}"
    if combined_map.include?(key)
      combined_map[key].hours += time.hours
      if time.description.present?
        if combined_map[key].description
          combined_map[key].description += "\n" + time.description
        else
          combined_map[key].description = time.description
        end
      end
    else
      combined_map[key] = time
      combined_times.push time
    end
  end

  def combine_ticket(combined_tickets, employees, worktime)
    combined_tickets[:n_entries] += 1
    combined_tickets[:sum] += worktime.hours
    combine_ticket_employees(combined_tickets, employees, worktime)
    combine_ticket_date_range(combined_tickets[:date], worktime)
    combined_tickets[:descriptions] << '"' + worktime.description + '"' if worktime.description?
  end

  def combine_ticket_employees(combined_tickets, employees, worktime)
    shortname = worktime.employee.shortname
    employees[shortname] = worktime.employee.to_s if employees[shortname].nil?
    if combined_tickets[:employees][shortname].nil?
      combined_tickets[:employees][shortname] = [worktime.hours, [worktime.description]]
    else
      combined_tickets[:employees][shortname][0] += worktime.hours
      combined_tickets[:employees][shortname][1] << worktime.description
    end
  end

  def combine_ticket_date_range(date_range, worktime)
    if date_range[0].nil?
      date_range[0] = worktime.work_date
    elsif worktime.work_date < date_range[0]
      date_range[0] = worktime.work_date
    end

    if date_range[1].nil?
      date_range[1] = worktime.work_date
    elsif worktime.work_date > date_range[1]
      date_range[1] = worktime.work_date
    end
  end
end
