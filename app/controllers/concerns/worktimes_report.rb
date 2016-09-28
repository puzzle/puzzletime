
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

      worktimes.each do |t|
        @tickets[ticket][:n_entries] += 1
        @tickets[ticket][:sum] += t.hours

        # employees involved in this ticket
        @employees[t.employee.shortname] = t.employee.to_s if @employees[t.employee.shortname].nil?
        if @tickets[ticket][:employees][t.employee.shortname].nil?
          @tickets[ticket][:employees][t.employee.shortname] = [t.hours, [t.description]]
        else
          @tickets[ticket][:employees][t.employee.shortname][0] += t.hours
          @tickets[ticket][:employees][t.employee.shortname][1] << t.description
        end

        # date range of this ticket
        if @tickets[ticket][:date][0].nil?
          @tickets[ticket][:date][0] = t.work_date
        else
          if t.work_date < @tickets[ticket][:date][0]
            @tickets[ticket][:date][0] = t.work_date
          end
        end

        if @tickets[ticket][:date][1].nil?
          @tickets[ticket][:date][1] = t.work_date
        else
          if t.work_date > @tickets[ticket][:date][1]
            @tickets[ticket][:date][1] = t.work_date
          end
        end

        @tickets[ticket][:descriptions] << '"' + t.description + '"' if t.description?
      end
    end
  end
end
