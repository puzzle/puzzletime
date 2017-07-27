#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class EmployeeStatisticsTest < ActiveSupport::TestCase

  setup :create_employments

  test '#employments_during with start and end date set' do
    period = Period.new(Date.new(2000, 1, 1), Date.new(2000, 1, 23))
    employments = statistics.employments_during(period)
    assert_equal 1, employments.count
    assert_equal 10, employments.first.percent
  end

  test '#employments_during with only start date set' do
    period = Period.new(Date.new(2000, 1, 1), nil)
    employments = statistics.employments_during(period)
    assert_equal 3, employments.count
    assert_equal 10, employments.first.percent
    assert_equal 20, employments.second.percent
    assert_equal 40, employments.third.percent
  end

  test '#employments_during with only end date set' do
    period = Period.new(nil, Date.new(2000, 1, 23))
    employments = statistics.employments_during(period)
    assert_equal 2, employments.count
    assert_equal 30, employments.first.percent
    assert_equal 10, employments.second.percent
  end

  private

  def create_employments
    employee.employments.create!(start_date: Date.new(2000, 1, 2),
                                 end_date: Date.new(2000, 1, 4),
                                 percent: 10)
    employee.employments.create!(start_date: Date.new(2000, 2, 1),
                                 end_date: Date.new(2000, 2, 4),
                                 percent: 20)
    employee.employments.create!(start_date: Date.new(1999, 12, 1),
                                 end_date: Date.new(1999, 12, 4),
                                 percent: 30)
    employee.employments.create!(start_date: Date.new(2000, 3, 1),
                                 end_date: nil,
                                 percent: 40)
  end

  def employee
    @employee ||= employees(:pascal)
  end

  def statistics
    @statistics ||= employee.statistics
  end

end
