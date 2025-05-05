# frozen_string_literal: true

#  Copyright (c) 2006-2018, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class OrderControllingHelperTest < ActionView::TestCase
  include OrderControllingHelper

  def setup
    @efforts_per_week_cumulated = {}
    @efforts_per_week_cumulated[Time.utc(2000, 1, 3)] = {
      billable: { amount: 10.0, hours: 1.0 },
      unbillable: { amount: 5.0, hours: 0.5 },
      planned_definitive: { amount: 0.0, hours: 0.0 },
      planned_provisional: { amount: 0.0, hours: 0.0 }
    }
    @efforts_per_week_cumulated[Time.utc(2000, 1, 3) + 1.week] = {
      billable: { amount: 10.0, hours: 1.0 },
      unbillable: { amount: 5.0, hours: 0.5 },
      planned_definitive: { amount: 0.0, hours: 0.0 },
      planned_provisional: { amount: 0.0, hours: 0.0 }
    }
    @efforts_per_week_cumulated[Time.utc(2000, 1, 3) + 2.weeks] = {
      billable: { amount: 20.0, hours: 2.0 },
      unbillable: { amount: 8.0, hours: 0.8 },
      planned_definitive: { amount: 2.0, hours: 0.02 },
      planned_provisional: { amount: 0.0, hours: 0.0 }
    }
  end

  test '#controlling_chart_labels' do
    assert_equal ['KW 01 2000', 'KW 02 2000', 'KW 03 2000'].to_json,
                 controlling_chart_labels
  end

  test '#controlling_chart_datasets' do
    assert_equal [
      { label: 'Verrechenbar', data: [10.0, 10.0, 20.0], tooltipData: [1.0, 1.0, 2.0], backgroundColor: '#69B978' },
      { label: 'Nicht verrechenbar', data: [5.0, 5.0, 8.0], tooltipData: [0.5, 0.5, 0.8], backgroundColor: '#f0e54e' },
      { label: 'Definitiv geplant', data: [0.0, 0.0, 2.0], tooltipData: [0.0, 0.0, 0.02], backgroundColor: '#4286e7' },
      { label: 'Provisorisch geplant', data: [0.0, 0.0, 0.0], tooltipData: [0.0, 0.0, 0.0], backgroundColor: '#9bcbd4' }
    ].to_json, controlling_chart_datasets
  end
end
