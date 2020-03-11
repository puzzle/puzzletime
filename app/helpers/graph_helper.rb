#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module GraphHelper
  def weekday_header
    names = I18n.t(:'date.day_names')[1..6] + [I18n.t(:'date.day_names')[0]]
    safe_join(names.collect { |n| content_tag(:th, n[0..1]) })
  end

  def week_header(period)
    cells = []
    period.step(7) { |day| cells << content_tag(:th, format('%02d', day.cweek)) }
    safe_join(cells)
  end

  def month_header(period)
    cells = []
    current_month = period.start_date.month
    span = 0
    period.step(7) do |day|
      if day.month != current_month
        cells << month_cell(current_month, span)
        current_month = day.month
        span = 0
      end
      span += 1
    end
    cells << month_cell(current_month, span)
    safe_join(cells)
  end

  def month_cell(month, span)
    name = span > 2 ? I18n.t(:'date.month_names')[month] : ''
    content_tag(:th, name, colspan: span)
  end

  def year_header
    cells = []
    current_year = @period.start_date.year
    span = 0
    @period.step(7) do |week|
      if week.year != current_year
        cells << year_cell(current_year, span)
        current_year = week.year
        span = 0
      end
      span += 1
    end
    cells << year_cell(current_year, span)
    safe_join(cells)
  end

  def year_cell(current_year, span)
    name = span > 2 ? current_year.to_s : ''
    content_tag(:th, name, colspan: span)
  end

  def weekbox_td(box, current)
    if box
      content_tag(:td, nil, style: "background-color: #{box.color};") do
        content_tag(:a, nil, class: 'has-tooltip') do
          safe_join([box.height, content_tag(:span, h(box.tooltip))])
        end
      end
    elsif current
      content_tag(:td, nil, class: 'current')
    else
      content_tag(:td)
    end
  end

  def timebox_div(box)
    worktime_link box.worktime do
      content = [image_tag('space.gif',
                           'height' => "#{box.height}px",
                           'style' => "background-color: #{box.color};")]
      content << content_tag(:span, h(box.tooltip)) unless box.tooltip.strip.empty?
      safe_join(content)
    end
  end

  def worktime_link(worktime, &block)
    url = if worktime && !worktime.new_record?
            if can?(:edit, worktime)
              url_for(controller: worktime.controller,
                      action: :edit,
                      id: worktime.id)
            else
              url_for(controller: 'ordertimes',
                      action: :index,
                      week_date: worktime.work_date)
            end
          end
    content_tag(:a, class: 'has-tooltip', href: url, &block)
  end

  def day_td(date, &block)
    content_tag(:td, class: ('holiday' if Holiday.non_working_day?(date)), &block)
  end
end
