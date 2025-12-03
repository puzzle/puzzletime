# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Billing
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
        ['Kunde', 'Status', 'Geleistet', 'Verrechenbar', 'Verrechnet', 'Verrechnung offen']
      end

      def row(e)
        [e.client, e.status.to_s, e.supplied_amount, e.billable_amount, e.billed_amount,
         e.not_billed_amount]
      end
    end
  end
end
