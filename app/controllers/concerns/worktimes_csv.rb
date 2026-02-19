# frozen_string_literal: true

#  Copyright (c) 2006-2024, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module WorktimesCsv
  extend ActiveSupport::Concern

  include CsvExportable

  private

  # @param stripped: include/exclude internal description in csv
  def send_worktimes_csv(worktimes, filename, stripped = false)
    csv_data = CSV.generate do |csv|
      csv << header(stripped)

      worktimes.each do |time|
        csv << row(time, stripped)
      end
    end

    send_csv(csv_data, filename)
  end

  def header(stripped = false)
    header = ['Datum', 'Stunden', 'Von Zeit', 'Bis Zeit', 'CHF', 'Stundenansatz CHF', 'Reporttyp',
              'Verrechenbar', 'Member', 'Position', 'Ticket', 'Bemerkungen']
    header << 'Interne Bemerkungen' unless stripped
    header
  end

  def row(time, stripped = false)
    data = [I18n.l(time.work_date), time.hours, (time.start_stop? ? I18n.l(time.from_start_time, format: :time) : ''),
            (time.start_stop? && time.to_end_time? ? I18n.l(time.to_end_time, format: :time) : ''),
            amount(time), offered_rate(time), time.report_type, time.billable, time.employee.label, time.account.label_verbose,
            time.ticket, time.description]
    data << time.internal_description unless stripped
    data
  end

  def offered_rate(time)
    return '-' unless time.respond_to?(:offered_rate)

    format('%<offered_rate>0.02f', offered_rate: time.offered_rate)
  end

  def amount(time)
    return '-' unless time.respond_to?(:amount)

    format('%<amount>0.02f', amount: time.amount)
  end
end
