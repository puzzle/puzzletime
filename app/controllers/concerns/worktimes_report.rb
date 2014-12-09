module Concerns
  module WorktimesReport
    extend ActiveSupport::Concern

    def send_worktimes_csv(worktimes, filename)
      set_csv_file_export_header(filename)
      csv_data = worktimes_csv(worktimes)
      send_data(csv_data, filename: filename, type: 'text/csv; charset=utf-8; header=present')
    end

    def set_csv_file_export_header(filename)
      if request.env['HTTP_USER_AGENT'] =~ /msie/i
        headers['Pragma'] = 'public'
        headers['Content-type'] = 'text/plain'
        headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
        headers['Expires'] = '0'
      else
        headers['Content-Type'] ||= 'text/csv'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      end
      headers['Last-Modified'] = Time.now.httpdate
    end

    private

    def worktimes_csv(worktimes)
      CSV.generate do |csv|
        csv << ['Datum', 'Stunden', 'Von Zeit', 'Bis Zeit', 'Reporttyp',
                'Verrechenbar', 'Mitarbeiter', 'Position', 'Ticket', 'Bemerkungen']
        worktimes.each do |time|
          csv << [I18n.l(time.work_date),
                  time.hours,
                  (time.start_stop? ? I18n.l(time.from_start_time, format: :time) : ''),
                  (time.start_stop? && time.to_end_time? ? I18n.l(time.to_end_time, format: :time) : ''),
                  time.report_type,
                  time.billable,
                  time.employee.label,
                  time.account.label_verbose,
                  time.ticket,
                  time.description]
        end
      end
    end

  end
end