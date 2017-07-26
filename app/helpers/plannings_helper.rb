# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module PlanningsHelper
  def planning_legend_path(legend)
    case legend
    when Employee then plannings_employee_path(legend)
    when AccountingPost then plannings_order_path(legend.order)
    else raise ArgumentError, "invalid argument #{legend.inspect}"
    end
  end

  def planning_row_id(employee_id, work_item_id)
    "planning_row_employee_#{employee_id}_work_item_#{work_item_id}"
  end

  def months_from_monday
    mondays = []
    @period.step(7) { |date| mondays << date }
    mondays.uniq(&:at_beginning_of_month).map do |first|
      Period.new(first, [@period.end_date, first.at_end_of_month].min)
    end
  end

  def weekly_planned_of_total_percent(board, date)
    content = "#{board.weekly_planned_percent(date).round}% / "
    content << if board.weekly_employment_percent(date)
                 "#{board.weekly_employment_percent(date).round}%"
               else
                 '-'
               end
  end
end
