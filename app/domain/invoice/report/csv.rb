# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Invoice
  class Report
    class Csv
      attr_reader :report

      def initialize(report)
        @report = report
      end

      def generate
        CSV.generate do |csv|
          csv << header

          report.entries.each do |e|
            csv << row(e)
          end
        end
      end

      private

      def header
        ['Referenz', 'Kunde / Auftrag', 'Leistungsperiode', 'Rechnungsdatum',
         'Fälligkeitsdatum', 'Status', 'Rechnungsbetrag', 'Total Stunden', 'OE',
         'Verantwortlich', 'Manuell']
      end

      def row(entry)
        order = entry.order
        [entry.reference, client(entry), entry.period, entry.billing_date, entry.due_date,
         format_invoice_status(entry.status), entry.total_amount, entry.total_hours, order.department,
         order.responsible, I18n.t("global.#{entry.manual_invoice?}")]
      end

      def client(entry)
        "#{entry.client}\n#{entry.order.work_item.path_shortnames}: #{entry.order}"
      end

      def format_invoice_status(val)
        IdValue.new(val, I18n.t("activerecord.attributes.invoice/statuses.#{val}"))
      end
    end
  end
end
