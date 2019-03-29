# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Reports::Revenue::Csv
  attr_reader :report, :entry

  def initialize(report)
    @report = report
  end

  def generate
    CSV.generate do |csv|
      csv << header

      entries.each do |e|
        @entry = e
        csv << row(entry)
      end

      csv << footer
    end
  end

  private

  def header
    [header_grouping, header_past_months, header_past_months_summary, header_future_months]
  end

  def header_grouping
    @report.grouping_name_human
  end

  def header_past_months
    @report.step_past_months { |date| l(date, format: :month) }
  end

  def header_past_months_summary
    ['Total', '⌀'] if report.past_months?
  end

  def header_future_months
    report.step_future_months { |date| l(date, format: :month) }
  end

  def entries
    @entries ||=
      if @report.hours_without_entry?
        @report.entries + [nil]
      else
        @report.entries
      end
  end

  def row
    [row_month, row_past_months, row_past_months_summary]
  end

  def row_month
    entry.presence || "#{report.grouping_name_human} nicht zugewiesen"
  end

  def row_past_months
    report.step_past_months do |date|
      format_number(report.ordertime_hours[[entry.try(:id), date]] || 0, 0)
    end
  end

  def row_past_months_summary
    if report.past_months?
      [
        format_number(@report.total_ordertime_hours_per_entry(entry), 0),
        format_number(@report.average_ordertime_hours_per_entry(entry), 0)
      ]
    end
  end

end
