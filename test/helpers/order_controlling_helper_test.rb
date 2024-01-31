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
      billable: 10.0,
      unbillable: 5.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    @efforts_per_week_cumulated[Time.utc(2000, 1, 3) + 1.week] = {
      billable: 10.0,
      unbillable: 5.0,
      planned_definitive: 0.0,
      planned_provisional: 0.0
    }
    @efforts_per_week_cumulated[Time.utc(2000, 1, 3) + 2.weeks] = {
      billable: 20.0,
      unbillable: 8.0,
      planned_definitive: 2.0,
      planned_provisional: 0.0
    }
  end

  test '#controlling_chart_labels' do
    assert_equal ['KW 01 2000', 'KW 02 2000', 'KW 03 2000'].to_json,
                 controlling_chart_labels
  end

  test '#controlling_chart_datasets' do
    assert_equal [
      { label: 'Verrechenbar', data: [10, 10, 20], backgroundColor: '#69B978' },
      { label: 'Nicht verrechenbar', data: [5, 5, 8], backgroundColor: '#f0e54e' },
      { label: 'Definitiv geplant', data: [0, 0, 2], backgroundColor: '#4286e7' },
      { label: 'Provisorisch geplant', data: [0, 0, 0], backgroundColor: '#9bcbd4' }
    ].to_json, controlling_chart_datasets
  end
end
