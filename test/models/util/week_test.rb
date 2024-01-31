#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class WeekTest < ActiveSupport::TestCase
  def test_from_string
    week = Week.from_string('2009 10')

    assert_equal 10, week.week
    assert_equal 2009, week.year

    week = Week.from_string('1999 01')

    assert_equal 1, week.week
    assert_equal 1999, week.year

    week = Week.from_string('1999 1')

    assert_equal 1, week.week
    assert_equal 1999, week.year
  end

  def test_from_integer
    week = Week.from_integer(200_811)

    assert_equal 11, week.week
    assert_equal 2008, week.year

    week = Week.from_integer(197_004)

    assert_equal 4, week.week
    assert_equal 1970, week.year
  end

  def test_to_integer
    week = Week.from_string('2007 01')

    assert_equal 200_701, week.to_integer

    week = Week.from_integer(200_811)

    assert_equal 200_811, week.to_integer
  end

  def test_from_date
    week = Week.from_date(Date.civil(2010, 3, 16))

    assert_equal 201_011, week.to_integer

    week = Week.from_date(Date.civil(2010, 3, 1))

    assert_equal 201_009, week.to_integer
  end

  def test_valid_week
    assert Week.valid?(201_001)
    assert !Week.valid?(201_053)
  end
end
