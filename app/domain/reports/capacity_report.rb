# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class CapacityReport < BaseCapacityReport
  def initialize(period)
    super(period, 'puzzletime_auslastung')
  end

  def to_csv
    CSV.generate do |csv|
      csv << ['Mitarbeiter', 'Projekt', 'Subprojekt', 'Verrechenbar', 'Nicht verrechenbar', 'Monat', 'Jahr']
      Employee.employed_ones(@period).each do |employee|
        monthly_periods.each do |period|
          order_time = 0
          processed_ids = []
          employee.alltime_leaf_work_items.each do |item|
            # get id of parent work item on (max) level 1
            id = item.path_ids[[1, item.path_ids.size - 1].min]
            next if processed_ids.include? id
            processed_ids.push id
            result = find_billable_time(employee, id, period)
            sum = result.collect(&:hours).sum
            parent = child = WorkItem.find(id)
            parent = child.parent if child.parent
            append_entry(csv,
                         employee,
                         period,
                         parent.label_verbose,
                         child == parent ? '' : child.label,
                         extract_billable_hours(result, true),
                         extract_billable_hours(result, false))
            order_time += sum
          end
          # include all absencetimes
          absences = employee_absences(employee, period)
          append_entry(csv, employee, period, 'Abwesenheiten', '', 0, absences)
        end
      end
    end
  end

  private

  def append_entry(csv, employee, period, work_item_label, sub_work_item_label, billable_hours, not_billable_hours)
    if (billable_hours + not_billable_hours).abs > 0.001
      csv << [employee.shortname,
              work_item_label,
              sub_work_item_label,
              billable_hours,
              not_billable_hours,
              period.start_date.month,
              period.start_date.year]
    end
  end

  def monthly_periods
    month_end = @period.start_date.end_of_month
    periods = [Period.new(@period.start_date, [month_end, @period.end_date].min)]
    while @period.end_date > month_end
      month_start = month_end + 1
      month_end = month_start.end_of_month
      periods.push Period.new(month_start, [month_end, @period.end_date].min)
    end
    periods
  end
end
