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

  def initialize(period = make_period)
    @period = period
  end

  def stats
    departments.map do |department|
      department_stats(department, @period)
    end.flatten(1)
  end

  private

  def departments
    Department.having_employees
  end

  def make_period
    last_week = Time.now.beginning_of_week - 1.day
    Period.new(last_week.beginning_of_week, last_week)
  end

  def department_stats(department, period)
    _company, department = Reports::Workload.new(period, department).summary

    fields =
      PROPERTIES.each_with_object({}) do |prop, memo|
        memo[prop] = department.send(prop)
      end

    {
      name: 'workload_last_week',
      fields: fields,
      tags: { department: department.label.to_s }
    }
  end
end
