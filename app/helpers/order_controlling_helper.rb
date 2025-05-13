# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module OrderControllingHelper
  def controlling_chart_labels
    @efforts_per_week_cumulated
      .keys
      .sort
      .map { |week| "KW #{week.strftime('%W')} #{week.strftime('%Y')}" }
      .to_json
      .html_safe
  end

  def controlling_chart_datasets
    [{ label: 'Verrechenbar', type: :billable, color: '#69B978' },
     { label: 'Nicht verrechenbar', type: :unbillable, color: '#f0e54e' },
     { label: 'Definitiv geplant', type: :planned_definitive, color: '#4286e7' },
     { label: 'Provisorisch geplant', type: :planned_provisional, color: '#9bcbd4' }]
      .map do |set|
        {
          label: set[:label],
          data: @efforts_per_week_cumulated
            .keys
            .sort
            .map { |week| @efforts_per_week_cumulated[week][set[:type]][:amount] },
          tooltipData: @efforts_per_week_cumulated
            .keys
            .sort
            .map { |week| @efforts_per_week_cumulated[week][set[:type]][:hours].round(2) },
          backgroundColor: set[:color]
        }
      end.to_json.html_safe
  end
end
