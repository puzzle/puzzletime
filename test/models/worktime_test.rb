# encoding: utf-8

require 'test_helper'

class WorktimeTest < ActiveSupport::TestCase

  def setup
    @worktime = Worktime.new
  end

  def test_fixture
    wt = Worktime.find(1)
    assert_kind_of Worktime, wt
    assert_equal worktimes(:wt_pz_allgemein).project_id, wt.project_id
    assert_equal projects(:allgemein).id, wt.account.id
    assert_equal employees(:pascal), wt.employee
    assert !wt.startStop?
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
    assert_equal @worktime.hours, 8
    @worktime.hours = 8.5
    assert_equal @worktime.hours, 8.5
    @worktime.hours = '8'
    assert_equal @worktime.hours, 8
    @worktime.hours = '8.5'
    assert_equal @worktime.hours, 8.5
    @worktime.hours = '.5'
    assert_equal @worktime.hours, 0.5
    @worktime.hours = '8:'
    assert_equal @worktime.hours, 8
    @worktime.hours = '8:30'
    assert_equal @worktime.hours, 8.5
    @worktime.hours = ':30'
    assert_equal @worktime.hours, 0.5
    @worktime.hours = 'afsdf'
    assert_equal @worktime.hours, 0
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
    assert_equal(time1.hour, time2.hour) &&
    assert_equal(time1.min, time2.min)
  end

end
