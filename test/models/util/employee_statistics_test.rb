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

  # rubocop:disable Lint/UselessAssignment
  test 'overtime works' do
    e = employees(:pascal)
    period = Period.new('01.12.2006', '11.12.2006')

    assert_difference('e.statistics.overtime(period).to_f', 1) do
      create_worktime
    end
  end

  test 'remaining worktime is affected by' do
    period = Period.new('01.12.2006', '11.12.2006')
    method = 'statistics.pending_worktime(period).to_f'

    # Working decreases the hours
    assert_difference(method, -1) { create_worktime }
    # Vacations decrease the hours
    assert_difference(method, -1) { create_absence(absence_id: 1) }
    # Unpaid absences decrease the hours
    assert_difference(method, -1) { create_absence(absence_id: 4) }
  end
  # rubocop:enable  Lint/UselessAssignment

  private

  def create_employments
    employee.employments.create!(start_date: Date.new(2000, 1, 2),
                                 end_date: Date.new(2000, 1, 4),
                                 percent: 10,
                                 employment_roles_employments: [Fabricate.build(:employment_roles_employment)])
    employee.employments.create!(start_date: Date.new(2000, 2, 1),
                                 end_date: Date.new(2000, 2, 4),
                                 percent: 20,
                                 employment_roles_employments: [Fabricate.build(:employment_roles_employment)])
    employee.employments.create!(start_date: Date.new(1999, 12, 1),
                                 end_date: Date.new(1999, 12, 4),
                                 percent: 30,
                                 employment_roles_employments: [Fabricate.build(:employment_roles_employment)])
    employee.employments.create!(start_date: Date.new(2000, 3, 1),
                                 end_date: nil,
                                 percent: 40,
                                 employment_roles_employments: [Fabricate.build(:employment_roles_employment)])
  end

  def create_worktime(**kwargs)
    args = {
      work_item_id: accounting_posts(:hitobito_demo_app).work_item_id,
      employee_id: employees(:pascal).id,
      work_date: Time.zone.local(2006, 12, 1, 12),
      hours: 1,
      report_type: 'absolute_day'
    }.merge(kwargs)
    Worktime.create!(args)
  end

  def create_absence(**kwargs)
    args = {
      absence_id: absences(:vacation).id,
      employee_id: employees(:pascal).id,
      work_date: Time.zone.local(2006, 12, 1, 12),
      hours: 1,
      report_type: 'absolute_day'
    }.merge(kwargs)
    Absencetime.create!(args)
  end

  def employee
    @employee ||= employees(:pascal)
  end

  def statistics
    @statistics ||= employee.statistics
  end
end
