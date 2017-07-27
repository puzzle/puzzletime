#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module WorktimesCsv
  extend ActiveSupport::Concern

  include CsvExportable

  private

  def send_worktimes_csv(worktimes, filename)
    csv_data = worktimes_csv(worktimes)
    send_csv(csv_data, filename)
  end

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
