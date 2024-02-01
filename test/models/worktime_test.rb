#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: worktimes
#
#  id              :integer          not null, primary key
#  absence_id      :integer
#  employee_id     :integer
#  report_type     :string(255)      not null
#  work_date       :date             not null
#  hours           :float
#  from_start_time :time
#  to_end_time     :time
#  description     :text
#  billable        :boolean          default(TRUE)
#  type            :string(255)
#  ticket          :string(255)
#  work_item_id    :integer
#  invoice_id      :integer
#

require 'test_helper'

class WorktimeTest < ActiveSupport::TestCase
  def setup
    @worktime = Worktime.new
  end

  def test_fixture
    wt = Worktime.find(1)

    assert_kind_of Worktime, wt
    assert_equal worktimes(:wt_pz_allgemein).work_item_id, wt.work_item_id
    assert_equal work_items(:allgemein).id, wt.account.id
    assert_equal employees(:pascal), wt.employee
    assert_not wt.start_stop?
    assert_nil wt.absence
  end

  def test_time_facade
    time_facade('from_start_time')
    time_facade('to_end_time')
  end

  def time_facade(field)
    now = Time.zone.now
    set_field(field, now)

    assert_equal_time_field now, field
    # set_field(field, now.to_s)
    # assert_equal_time_field now, field
    set_field(field, '3')

    assert_equal_time_field Time.parse('3:00'), field
    set_field(field, '4:14')

    assert_equal_time_field Time.parse('4:14'), field
    set_field(field, '23:14')

    assert_equal_time_field Time.parse('23:14'), field
    set_field(field, '4.25')

    assert_equal_time_field Time.parse('4:15'), field
    set_field(field, '4.0')

    assert_equal_time_field Time.parse('4:00'), field
  end

  def test_time_facade_invalid
    time_facade_invalid('from_start_time')
    time_facade_invalid('to_end_time')
  end

  def time_facade_invalid(field)
    set_field(field, '')

    assert_nil get_field(field)
    set_field(field, 'adfasf')

    assert_nil get_field(field)
    set_field(field, 'ss:22')

    assert_nil get_field(field)
    set_field(field, '1:ss')

    assert_nil get_field(field)
    set_field(field, '1:88')

    assert_nil get_field(field)
    set_field(field, '28')

    assert_nil get_field(field)
    set_field(field, '28:22')

    assert_nil get_field(field)
    set_field(field, '-8')

    assert_nil get_field(field)
  end

  def test_hours
    time = Time.zone.now
    @worktime.hours = 8

    assert_equal 8, @worktime.hours
    @worktime.hours = 8.5

    assert_in_delta(@worktime.hours, 8.5)
    @worktime.hours = '8'

    assert_equal 8, @worktime.hours
    @worktime.hours = '8.5'

    assert_in_delta(@worktime.hours, 8.5)
    @worktime.hours = '.5'

    assert_in_delta(@worktime.hours, 0.5)
    @worktime.hours = '8:'

    assert_equal 8, @worktime.hours
    @worktime.hours = '8:30'

    assert_in_delta(@worktime.hours, 8.5)
    @worktime.hours = ':30'

    assert_in_delta(@worktime.hours, 0.5)
    @worktime.hours = 'afsdf'

    assert_equal 0, @worktime.hours
  end

  def test_start_stop_validation
    @worktime.report_type = ReportType::StartStopType::INSTANCE
    @worktime.employee = employees(:various_pedro)
    @worktime.work_date = Time.zone.today

    assert_not @worktime.valid?
    @worktime.from_start_time = '8:00'
    @worktime.to_end_time = '9:00'

    assert_predicate @worktime, :valid?, @worktime.errors.full_messages.join(', ')
    @worktime.to_end_time = '7:00'

    assert_not @worktime.valid?
    @worktime.to_end_time = '-3'

    assert_not @worktime.valid?
  end

  def test_report_type_guessing_with_start_time
    @worktime.employee = employees(:pascal)
    @worktime.work_date = Time.zone.today
    @worktime.from_start_time = '08:00'
    @worktime.hours = 5

    assert_not @worktime.valid?
    assert_equal [:to_end_time], @worktime.errors.attribute_names
    assert_predicate @worktime, :start_stop?
    assert_in_delta(0.0, @worktime.hours)
  end

  def test_report_type_guessing_with_start_and_end_time
    @worktime.employee = employees(:pascal)
    @worktime.work_date = Time.zone.today
    @worktime.from_start_time = '08:00'
    @worktime.to_end_time = '10:40'
    @worktime.hours = 5

    assert_predicate @worktime, :valid?
    assert_predicate @worktime, :start_stop?
    assert_in_delta 2.66667, @worktime.hours
  end

  def test_template
    newWorktime = Worktime.find(1).template

    assert_not_nil newWorktime
    assert_equal worktimes(:wt_pz_allgemein).work_item_id, newWorktime.work_item_id
    assert_equal work_items(:allgemein).id, newWorktime.account.id
    assert_equal employees(:pascal), newWorktime.employee
  end

  def test_strip_ticket
    assert_equal 'hello', Worktime.new(ticket: 'hello ').tap(&:valid?).ticket
    assert_equal 'hello', Worktime.new(ticket: ' hello').tap(&:valid?).ticket
    assert_equal 'hello', Worktime.new(ticket: ' hello ').tap(&:valid?).ticket
  end

  private

  def get_field(field)
    @worktime.send(field)
  end

  def set_field(field, value)
    @worktime.send(field + '=', value)
  end

  def assert_equal_time_field(time, field)
    assert_equal_time time, @worktime.send(field)
  end

  def assert_equal_time(time1, time2)
    if time1.is_a?(Time) && time2.is_a?(Time)
      assert_equal(time1.hour, time2.hour) &&
        assert_equal(time1.min, time2.min)
    else
      assert_equal time1, time2
    end
  end
end
