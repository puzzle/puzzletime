#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Reports::Revenue
  class BI
    def initialize(window = 3.months)
      @window = window
    end

    def stats
      now = Time.now

      report = report(now, @window)
      revenue(now, report)
    end

    private

    def report(time, window)
      period =
        Period.new(
          (time - window).beginning_of_month,
          (time + window).end_of_month
        )
      Reports::Revenue::Department.new(period, {})
    end

    def revenue(now, report)
      report.entries.each_with_object([]) do |entry, memo|
        report.step_past_months do |date|
          memo << revenue_stats(report, entry, date, now, :ordertime)
        end
        report.step_future_months do |date|
          memo << revenue_stats(report, entry, date, now, :planning)
        end
      end.compact
    end

    def revenue_stats(report, entry, date, now, source)
      volume = find_volume(report, entry, date, source)
      return nil if volume.nil?

      {
        name: "revenue_#{source}",
        fields: { volume: volume },
        tags: tags(entry, date, now)
      }
    end

    def tags(entry, date, now)
      delta = distance_in_months(now, date)
      sign = delta < 0 ? '-' : '+'

      delta_tag = "#{sign} #{delta.abs} months"
      month_tag = date.strftime('%Y-%m')

      { time_delta: delta_tag, month: month_tag, department: entry.to_s }
    end

    def distance_in_months(from, to)
      (to.year * 12 + to.month) - (from.year * 12 + from.month)
    end

    def find_volume(report, entry, date, source)
      data =
        source == :ordertime ? report.ordertime_hours : report.planning_hours
      data[[entry.try(:id), date]]
    end
  end
end
