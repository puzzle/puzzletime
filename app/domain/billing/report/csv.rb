# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Billing
  class Report
    # CSV export of the billing report.
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
        ['Kunde', 'Status', 'Geleistet', 'Verrechenbar', 'Verrechnet', 'Verrechnung offen']
      end

      def row(entry)
        [entry.client, entry.status.to_s, entry.supplied_amount, entry.billable_amount, entry.billed_amount,
         entry.not_billed_amount]
      end
    end
  end
end
