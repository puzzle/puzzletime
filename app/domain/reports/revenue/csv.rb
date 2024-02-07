# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Reports
  module Revenue
    class Csv
      attr_reader :report, :entry

      def initialize(report)
        @report = report
      end

      def generate
        CSV.generate do |csv|
          csv << header

          entries.each do |e|
            @entry = e
            csv << row
          end

          csv << footer
        end
      end

      private

      # Headers

      def header
        [header_grouping, header_past_months, header_past_months_summary, header_future_months].flatten
      end

      def header_grouping
        report.grouping_name_human
      end

      def header_past_months
        out = []
        report.step_past_months { |date| out << l(date, format: :month) }
        out
      end

      def header_past_months_summary
        ['Total', '⌀'] if report.past_months?
      end

      def header_future_months
        out = []
        report.step_future_months { |date| out << l(date, format: :month) }
        out
      end

      def entries
        @entries ||=
          if report.hours_without_entry?
            report.entries + [nil]
          else
            report.entries
          end
      end

      # Rows

      def row
        [row_grouping, row_past_months, row_past_months_summary, row_future_months].flatten
      end

      def row_grouping
        entry.presence || "#{report.grouping_name_human} nicht zugewiesen"
      end

      def row_past_months
        out = []
        report.step_past_months do |date|
          out << format_number(report.ordertime_hours[[entry.try(:id), date]] || 0, 0)
        end
        out
      end

      def row_past_months_summary
        return unless report.past_months?

        [
          format_number(report.total_ordertime_hours_per_entry(entry), 0),
          format_number(report.average_ordertime_hours_per_entry(entry), 0)
        ]
      end

      def row_future_months
        out = []
        report.step_future_months do |date|
          out << format_number(report.planning_hours[[entry.try(:id), date]] || 0, 0)
        end
        out
      end

      # Footer

      def footer
        [footer_total, footer_past_months, footer_past_months_summary, footer_future_months].flatten
      end

      def footer_total
        'Total'
      end

      def footer_past_months
        out = []
        report.step_past_months do |date|
          out << format_number(report.total_ordertime_hours_per_month[date] || 0, 0)
        end
        out
      end

      def footer_past_months_summary
        return unless report.past_months?

        [
          format_number(report.total_ordertime_hours_overall, 0),
          format_number(report.average_ordertime_hours_overall, 0)
        ]
      end

      def footer_future_months
        out = []
        report.step_future_months do |date|
          out << format_number(report.total_planning_hours_per_month[date] || 0, 0)
        end
        out
      end

      def l(...)
        I18n.l(...)
      end

      def format_number(number, precision = nil)
        ActionController::Base.helpers.number_with_precision(number, precision:, delimiter: nil, separator: '.')
      end
    end
  end
end
