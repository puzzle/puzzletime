# encoding: utf-8
# == Schema Information
#
# Table name: plannings
#
#  id              :integer          not null, primary key
#  employee_id     :integer          not null
#  start_week      :integer          not null
#  end_week        :integer
#  definitive      :boolean          default(FALSE), not null
#  description     :text
#  monday_am       :boolean          default(FALSE), not null
#  monday_pm       :boolean          default(FALSE), not null
#  tuesday_am      :boolean          default(FALSE), not null
#  tuesday_pm      :boolean          default(FALSE), not null
#  wednesday_am    :boolean          default(FALSE), not null
#  wednesday_pm    :boolean          default(FALSE), not null
#  thursday_am     :boolean          default(FALSE), not null
#  thursday_pm     :boolean          default(FALSE), not null
#  friday_am       :boolean          default(FALSE), not null
#  friday_pm       :boolean          default(FALSE), not null
#  created_at      :datetime
#  updated_at      :datetime
#  is_abstract     :boolean
#  abstract_amount :decimal(, )
#  work_item_id    :integer          not null
#


require 'test_helper'

class PlanningTest < ActiveSupport::TestCase
  def test_overlapping_with_no_repeat_and_no_repeat
    p1 = build_planning(201_010, 201_010)
    p1.save!

    # test p1 with himself
    assert !p1.overlaps?(p1)

    # test p2 after p1
    p2 = build_planning(201_011, 201_011)
    assert !p1.overlaps?(p2)

    # test p2 before p1
    p2 = build_planning(201_009, 201_009)
    assert !p1.overlaps?(p2)

    # test overlapping
    p2 = build_planning(201_010, 201_010)
    assert p1.overlaps?(p2)
  end

  def test_overlapping_with_no_repeat_and_repeat_until
    p1 = build_planning(201_010, 201_010)
    p1.save!

    # test p1 with himself
    assert !p1.overlaps?(p1)

    # test p2 after p1
    p2 = build_planning(201_011, 201_020)
    assert !p1.overlaps?(p2)

    # test p2 before p1
    p2 = build_planning(201_001, 201_009)
    assert !p1.overlaps?(p2)

    # test overlapping
    p2 = build_planning(201_001, 201_020)
    assert p1.overlaps?(p2)
  end

  def test_overlapping_with_no_repeat_and_repeat_forever
    p1 = build_planning(201_010, 201_010)
    p1.save!

    # test p1 with himself
    assert !p1.overlaps?(p1)

    # test p2 after p1
    p2 = build_planning(201_011, nil)
    assert !p1.overlaps?(p2)

    # test p2 before p1
    p2 = build_planning(201_001, nil)
    assert p1.overlaps?(p2)
  end

  def test_overlapping_with_repeat_until_and_no_repeat
    p1 = build_planning(201_010, 201_020)
    p1.save!

    # test p1 with himself
    assert !p1.overlaps?(p1)

    # test p2 after p1
    p2 = build_planning(201_021, 201_021)
    assert !p1.overlaps?(p2)

    # test p2 before p1
    p2 = build_planning(201_009, 201_009)
    assert !p1.overlaps?(p2)

    # test overlapping
    p2 = build_planning(201_015, 201_015)
    assert p1.overlaps?(p2)
  end

  def test_overlapping_with_repeat_until_and_repeat_until
    p1 = build_planning(201_010, 201_020)
    p1.save!

    # test p1 with himself
    assert !p1.overlaps?(p1)

    # test p2 after p1
    p2 = build_planning(201_021, 201_031)
    assert !p1.overlaps?(p2)

    # test p2 before p1
    p2 = build_planning(201_001, 201_009)
    assert !p1.overlaps?(p2)

    # test overlapping
    p2 = build_planning(201_005, 201_015)
    assert p1.overlaps?(p2)
  end

  def test_overlapping_with_repeat_until_and_repeat_forever
    p1 = build_planning(201_010, 201_020)
    p1.save!

    # test p1 with himself
    assert !p1.overlaps?(p1)

    # test p2 after p1
    p2 = build_planning(201_021, nil)
    assert !p1.overlaps?(p2)

    # test p2 before p1
    p2 = build_planning(201_001, nil)
    assert p1.overlaps?(p2)
  end

  def test_overlapping_with_repeat_forever_and_no_repeat
    p1 = build_planning(201_010, nil)
    p1.save!

    # test p1 with himself
    assert !p1.overlaps?(p1)

    # test p2 after p1
    p2 = build_planning(201_011, 201_011)
    assert p1.overlaps?(p2)

    # test p2 before p1
    p2 = build_planning(201_009, 201_009)
    assert !p1.overlaps?(p2)
  end

  def test_overlapping_with_repeat_forever_and_repeat_until
    p1 = build_planning(201_010, nil)
    p1.save!

    # test p1 with himself
    assert !p1.overlaps?(p1)

    # test p2 after p1
    p2 = build_planning(201_011, 201_020)
    assert p1.overlaps?(p2)

    # test p2 before p1
    p2 = build_planning(201_001, 201_009)
    assert !p1.overlaps?(p2)
  end

  def test_overlapping_with_repeat_forever_and_repeat_forever
    p1 = build_planning(201_010, nil)
    p1.save!

    # test p1 with himself
    assert !p1.overlaps?(p1)

    # test p2 after p1
    p2 = build_planning(201_011, nil)
    assert p1.overlaps?(p2)

    # test p2 before p1
    p2 = build_planning(201_001, nil)
    assert p1.overlaps?(p2)
  end

  def test_period_planning_time_with_abstract_planning_and_no_repeat
    p = build_planning_simple(201_010, 201_010)
    p.is_abstract = true
    p.abstract_amount = 20.0

    # period within
    assert_planning_hours p, 6.4, Date.civil(2010, 3, 8), Date.civil(2010, 3, 11)

    # period starting before
    assert_planning_hours p, 3.2, Date.civil(2010, 3, 1), Date.civil(2010, 3, 9)

    # period ending after
    assert_planning_hours p, 3.2, Date.civil(2010, 3, 11), Date.civil(2010, 3, 31)

    # period starting and ending outside
    assert_planning_hours p, 8.0, Date.civil(2010, 3, 1), Date.civil(2010, 3, 31)

    p.abstract_amount = 50.0
    assert_planning_hours p, 16.0, Date.civil(2010, 3, 8), Date.civil(2010, 3, 11)
  end

  def test_period_planning_time_with_abstract_planning_and_repeat_until
    p = build_planning_simple(201_010, 201_011)
    p.is_abstract = true
    p.abstract_amount = 20.0

    # period within
    assert_planning_hours p, 6.4, Date.civil(2010, 3, 11), Date.civil(2010, 3, 16)

    # period starting before
    assert_planning_hours p, 3.2, Date.civil(2010, 3, 1), Date.civil(2010, 3, 9)

    # period ending after
    assert_planning_hours p, 3.2, Date.civil(2010, 3, 18), Date.civil(2010, 3, 31)

    # period starting and ending outside
    assert_planning_hours p, 16, Date.civil(2010, 3, 1), Date.civil(2010, 3, 31)

    p.abstract_amount = 50.0
    assert_planning_hours p, 16.0, Date.civil(2010, 3, 11), Date.civil(2010, 3, 16)
  end

  def test_period_planning_time_with_abstract_planning_and_repeat_forever
    p = build_planning_simple(201_010, nil)
    p.is_abstract = true
    p.abstract_amount = 20.0

    # period within
    assert_planning_hours p, 6.4, Date.civil(2010, 3, 8), Date.civil(2010, 3, 11)

    # period starting before
    assert_planning_hours p, 3.2, Date.civil(2010, 3, 1), Date.civil(2010, 3, 9)

    # period ending after
    assert_planning_hours p, 24.0, Date.civil(2010, 3, 11), Date.civil(2010, 3, 31)

    # period starting and ending outside
    assert_planning_hours p, 28.8, Date.civil(2010, 3, 1), Date.civil(2010, 3, 31)

    p.abstract_amount = 50.0
    assert_planning_hours p, 16.0, Date.civil(2010, 3, 8), Date.civil(2010, 3, 11)
  end

  def test_period_planning_time_with_concrete_planning_and_no_repeat
    p = build_planning_simple(201_010, 201_010)
    p.is_abstract = false
    p.monday_am = true
    p.monday_pm = true
    p.tuesday_am = true
    p.tuesday_pm = true
    p.wednesday_am = true

    # period within
    assert_planning_hours p, 16.0, Date.civil(2010, 3, 8), Date.civil(2010, 3, 9)

    # period starting before
    assert_planning_hours p, 16.0, Date.civil(2010, 3, 1), Date.civil(2010, 3, 9)

    # period ending after
    assert_planning_hours p, 12.0, Date.civil(2010, 3, 9), Date.civil(2010, 3, 31)

    # period starting and ending outside
    assert_planning_hours p, 20.0, Date.civil(2010, 3, 1), Date.civil(2010, 3, 31)

    p.wednesday_pm = true
    p.thursday_am = true
    p.thursday_pm = true
    p.friday_am = true
    p.friday_pm = true
    assert_planning_hours p, 40.0, Date.civil(2010, 3, 8), Date.civil(2010, 3, 12)
  end

  def test_period_planning_time_with_concrete_planning_and_repeat_until
    p = build_planning_simple(201_010, 201_011)
    p.is_abstract = false
    p.monday_am = true
    p.monday_pm = true
    p.tuesday_am = true
    p.tuesday_pm = true
    p.wednesday_am = true

    # period within
    assert_planning_hours p, 36.0, Date.civil(2010, 3, 8), Date.civil(2010, 3, 16)

    # period starting before
    assert_planning_hours p, 16.0, Date.civil(2010, 3, 1), Date.civil(2010, 3, 9)

    # period ending after
    assert_planning_hours p, 12.0, Date.civil(2010, 3, 16), Date.civil(2010, 3, 31)

    # period starting and ending outside
    assert_planning_hours p, 40.0, Date.civil(2010, 3, 1), Date.civil(2010, 3, 31)

    p.wednesday_pm = true
    p.thursday_am = true
    p.thursday_pm = true
    p.friday_am = true
    p.friday_pm = true
    assert_planning_hours p, 56.0, Date.civil(2010, 3, 8), Date.civil(2010, 3, 16)
  end

  def test_period_planning_time_with_concrete_planning_and_repeat_forever
    p = build_planning_simple(201_010, nil)
    p.is_abstract = false
    p.monday_am = true
    p.monday_pm = true
    p.tuesday_am = true
    p.tuesday_pm = true
    p.wednesday_am = true

    # period within
    assert_planning_hours p, 16.0, Date.civil(2010, 3, 8), Date.civil(2010, 3, 9)

    # period starting before
    assert_planning_hours p, 16.0, Date.civil(2010, 3, 1), Date.civil(2010, 3, 9)

    # period ending after
    assert_planning_hours p, 72.0, Date.civil(2010, 3, 9), Date.civil(2010, 3, 31)

    # period starting and ending outside
    assert_planning_hours p, 80.0, Date.civil(2010, 3, 1), Date.civil(2010, 3, 31)

    p.wednesday_pm = true
    p.thursday_am = true
    p.thursday_pm = true
    p.friday_am = true
    p.friday_pm = true
    assert_planning_hours p, 56.0, Date.civil(2010, 3, 8), Date.civil(2010, 3, 16)
  end

  private

  def build_planning(start_week, end_week)
    Planning.new(start_week: start_week,
                 end_week: end_week,
                 monday_am: true,
                 employee_id: employees(:long_time_john).id,
                 work_item_id: work_items(:allgemein).id)
  end

  def build_planning_simple(start_week, end_week)
    Planning.new(start_week: start_week,
                 end_week: end_week,
                 employee_id: employees(:long_time_john).id,
                 work_item_id: work_items(:allgemein).id)
  end

  def assert_planning_hours(planning, hours, period_start_date, period_end_date)
    period = Period.retrieve(period_start_date, period_end_date)
    assert_equal hours.to_f, planning.period_planning_time(period).to_f
  end
end
