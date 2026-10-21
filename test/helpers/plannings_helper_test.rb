# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

# Test PlanningsHelper
class PlanningsHelperTest < ActionView::TestCase
  test 'planning_heatmap_class without planning and employment' do
    assert_nil planning_heatmap_class(nil, nil)
    assert_nil planning_heatmap_class(0, nil)
    assert_nil planning_heatmap_class(0, 0)
  end

  test 'planning_heatmap_class zero planning' do
    assert_equal 'heat-0', planning_heatmap_class(0, 100)
    assert_equal 'heat-0', planning_heatmap_class(0.0, 80.0)
  end

  test 'planning_heatmap_class small planning is visible' do
    assert_equal 'heat-10', planning_heatmap_class(0.5, 100)
    assert_equal 'heat-10', planning_heatmap_class(9.9, 100)
  end

  test 'planning_heatmap_class buckets by 10 percent steps' do
    assert_equal 'heat-10', planning_heatmap_class(10, 100)
    assert_equal 'heat-50', planning_heatmap_class(59, 100)
    assert_equal 'heat-60', planning_heatmap_class(60, 100)
    assert_equal 'heat-90', planning_heatmap_class(90, 100)
  end

  test 'planning_heatmap_class within one percent of employment is full' do
    assert_equal 'heat-100', planning_heatmap_class(100, 100)
    assert_equal 'heat-100', planning_heatmap_class(99.5, 100)
    assert_equal 'heat-100', planning_heatmap_class(100.5, 100)
  end

  test 'planning_heatmap_class above employment is over' do
    assert_equal 'heat-over', planning_heatmap_class(105, 100)
    assert_equal 'heat-over', planning_heatmap_class(20, nil)
    assert_equal 'heat-over', planning_heatmap_class(20, 0)
  end

  test 'planning_heatmap_class with float totals' do
    assert_equal 'heat-60', planning_heatmap_class(1234.5, 2000.0)
  end
end
