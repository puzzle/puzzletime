# == Schema Information
#
# Table name: working_conditions
#
#  id                     :integer          not null, primary key
#  valid_from             :date
#  vacation_days_per_year :decimal(5, 2)    not null
#  must_hours_per_day     :decimal(4, 2)    not null
#

require 'test_helper'

class WorkingConditionTest < ActiveSupport::TestCase

  setup { WorkingCondition.clear_cache }

  test 'second condition with valid_from is fine' do
    c = WorkingCondition.new(valid_from: Date.new(2012, 1, 1),
                             vacation_days_per_year: 20,
                             must_hours_per_day: 8.4)
    assert_valid c
  end

  test 'only one without valid_from may exist' do
    c = WorkingCondition.new(vacation_days_per_year: 20,
                             must_hours_per_day: 8.4)
    assert_not_valid c, :valid_from
  end

  test 'assigning valid_from to default is not possible' do
    c = working_conditions(:default)
    c.valid_from = Date.today
    assert_not_valid c, :valid_from
  end

  test 'clearing valid_from from second is not possible' do
    c = WorkingCondition.create!(valid_from: Date.new(2012, 1, 1),
                                 vacation_days_per_year: 20,
                                 must_hours_per_day: 8.4)
    c.valid_from = ''
    assert_not_valid c, :valid_from
  end

  test 'removing default is not possible' do
    c = working_conditions(:default)
    assert_no_difference('WorkingCondition.count') do
      c.destroy
    end
    assert !c.destroyed?
  end

  test 'removing second is possible' do
    c = WorkingCondition.create!(valid_from: Date.new(2012, 1, 1),
                                 vacation_days_per_year: 20,
                                 must_hours_per_day: 8.4)
    c.destroy
    assert c.destroyed?
  end

  test 'each_for iterates over single condition' do
    period = Period.new(Date.new(2012, 1, 1), Date.new(2014, 12, 31))
    ps = []
    vs = []
    WorkingCondition.each_period_of(:vacation_days_per_year, period) do |p, v|
      ps << p
      vs << v
    end
    assert_equal 1, ps.size
    assert_equal Date.new(2012, 1, 1), ps.first.start_date
    assert_equal Date.new(2014, 12, 31), ps.first.end_date
    assert_equal 25, vs.first
  end

  test 'each_for iterates over multiple conditions' do
    WorkingCondition.create!(valid_from: Date.new(2010, 1, 1),
                             vacation_days_per_year: 10,
                             must_hours_per_day: 8.4)
    WorkingCondition.create!(valid_from: Date.new(2011, 1, 1),
                             vacation_days_per_year: 11,
                             must_hours_per_day: 8.4)
    WorkingCondition.create!(valid_from: Date.new(2013, 1, 1),
                             vacation_days_per_year: 13,
                             must_hours_per_day: 8.4)

    period = Period.new(Date.new(2012, 1, 1), Date.new(2013, 12, 31))
    ps = []
    vs = []
    WorkingCondition.each_period_of(:vacation_days_per_year, period) do |p, v|
      ps << p
      vs << v
    end
    assert_equal 2, ps.size
    assert_equal Date.new(2012, 1, 1), ps.first.start_date
    assert_equal Date.new(2012, 12, 31), ps.first.end_date
    assert_equal Date.new(2013, 1, 1), ps.second.start_date
    assert_equal Date.new(2013, 12, 31), ps.second.end_date
    assert_equal 11, vs.first
    assert_equal 13, vs.second
  end

  test 'each_for iterates from first to last day of period' do
    WorkingCondition.create!(valid_from: Date.new(2010, 1, 1),
                             vacation_days_per_year: 10,
                             must_hours_per_day: 8.4)
    WorkingCondition.create!(valid_from: Date.new(2011, 1, 1),
                             vacation_days_per_year: 11,
                             must_hours_per_day: 8.4)
    WorkingCondition.create!(valid_from: Date.new(2013, 1, 1),
                             vacation_days_per_year: 13,
                             must_hours_per_day: 8.4)
    WorkingCondition.create!(valid_from: Date.new(2015, 1, 1),
                             vacation_days_per_year: 15,
                             must_hours_per_day: 8.4)
    WorkingCondition.create!(valid_from: Date.new(2017, 1, 1),
                             vacation_days_per_year: 17,
                             must_hours_per_day: 8.4)

    period = Period.new(Date.new(2011, 1, 1), Date.new(2014, 12, 31))
    ps = []
    vs = []
    WorkingCondition.each_period_of(:vacation_days_per_year, period) do |p, v|
      ps << p
      vs << v
    end
    assert_equal 2, ps.size
    assert_equal Date.new(2011, 1, 1), ps.first.start_date
    assert_equal Date.new(2012, 12, 31), ps.first.end_date
    assert_equal Date.new(2013, 1, 1), ps.second.start_date
    assert_equal Date.new(2014, 12, 31), ps.second.end_date
    assert_equal 11, vs.first
    assert_equal 13, vs.second
  end

  test 'each_for iterates from first to last day of period with just one more' do
    WorkingCondition.create!(valid_from: Date.new(2010, 1, 1),
                             vacation_days_per_year: 10,
                             must_hours_per_day: 8.4)
    WorkingCondition.create!(valid_from: Date.new(2011, 1, 1),
                             vacation_days_per_year: 11,
                             must_hours_per_day: 8.4)
    WorkingCondition.create!(valid_from: Date.new(2013, 1, 1),
                             vacation_days_per_year: 13,
                             must_hours_per_day: 8.4)
    WorkingCondition.create!(valid_from: Date.new(2015, 1, 1),
                             vacation_days_per_year: 15,
                             must_hours_per_day: 8.4)
    WorkingCondition.create!(valid_from: Date.new(2017, 1, 1),
                             vacation_days_per_year: 17,
                             must_hours_per_day: 8.4)

    period = Period.new(Date.new(2010, 12, 31), Date.new(2015, 1, 1))
    ps = []
    vs = []
    WorkingCondition.each_period_of(:vacation_days_per_year, period) do |p, v|
      ps << p
      vs << v
    end
    assert_equal 4, ps.size
    assert_equal Date.new(2010, 12, 31), ps.first.start_date
    assert_equal Date.new(2010, 12, 31), ps.first.end_date
    assert_equal Date.new(2011, 1, 1), ps.second.start_date
    assert_equal Date.new(2012, 12, 31), ps.second.end_date
    assert_equal Date.new(2013, 1, 1), ps.third.start_date
    assert_equal Date.new(2014, 12, 31), ps.third.end_date
    assert_equal Date.new(2015, 1, 1), ps.fourth.start_date
    assert_equal Date.new(2015, 1, 1), ps.fourth.end_date
    assert_equal [10, 11, 13, 15], vs
  end
end
