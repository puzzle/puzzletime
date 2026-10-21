# frozen_string_literal: true

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

  def row_update_html(ids, items)
    is_order_board = @board.is_a? Plannings::OrderBoard
    period_total = is_order_board ? @board.total_row_planned_hours(*ids, true) : nil

    j(
      render(
        'row',
        items: items,
        legend: @board.row_legend(*ids),
        row_total: @board.total_row_planned_hours(*ids),
        row_total_period: period_total,
        row_total_overall: is_order_board
      )
    )
  end

  # Heatmap bucket for a planned percent relative to the employment percent.
  # Returns a css class (heat-0 … heat-90, heat-100, heat-over) or nil.
  def planning_heatmap_class(planned_percent, employed_percent)
    planned = planned_percent.to_f
    employed = employed_percent.to_f
    return nil if planned.zero? && employed.zero?
    return 'heat-0' if planned.zero?
    return 'heat-over' if employed.zero?
    return 'heat-100' if (planned - employed).abs < 1
    return 'heat-over' if planned > employed

    ratio = planned * 100 / employed
    "heat-#{[(ratio / 10).floor * 10, 10].max}"
  end

  # Remote sort link for the company planning header. `current` is the active sort ({ key:, dir:, week: }).
  # The active column is bold and shows its direction; clicking it flips the direction,
  # clicking another column starts with its default direction.
  def company_sort_link(label, current:, sort:, default_dir:, sort_week: nil)
    active = current[:key] == sort && (sort != 'week' || current[:week] == sort_week)
    dir = if active
            current[:dir] == 'asc' ? 'desc' : 'asc'
          else
            default_dir
          end
    params = { sort: sort, sort_dir: dir }
    params[:sort_week] = sort_week if sort == 'week'
    return link_to(label, plannings_company_path(params), remote: true) unless active

    safe_join([link_to(label, plannings_company_path(params), remote: true, class: 'sort-active'),
               current[:dir] == 'asc' ? ' ▲' : ' ▼'])
  end
end
