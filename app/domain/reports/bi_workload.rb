#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Reports::BIWorkload
  PROPERTIES = %i[
    employment_fte
    must_hours
    ordertime_hours
    paid_absence_hours
    worktime_balance
    external_client_hours
    billable_hours
    workload
    billability
    absolute_billability
  ]

  def initialize(today = DateTime.now)
    @today = today
  end

  def stats
    periods.flat_map do |period, period_tags|
      departments.flat_map do |department|
        department_stats(department, period, period_tags)
      end
    end
  end

  private

  def periods
    last_week = @today - 1.week
    last_month = @today - 1.month

    [
      [
        Period.new(last_week.beginning_of_week, last_week.end_of_week),
        { week: last_week.strftime('CW %-V') }
      ],
      [
        Period.new(last_month.beginning_of_month, last_month.end_of_month),
        { month: last_month.strftime('%Y-%m') }
      ]
    ]
  end

  def departments
    Department.having_employees
  end

  def make_period; end

  def department_stats(department, period, tags)
    _company, department = Reports::Workload.new(period, department).summary

    fields =
      PROPERTIES.each_with_object({}) do |prop, memo|
        memo[prop] = department.send(prop)
      end

    {
      name: 'workload',
      fields: fields,
      tags: { department: department.label.to_s }.merge(tags)
    }
  end
end
