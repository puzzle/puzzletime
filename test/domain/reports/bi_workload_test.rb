#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class BIWorkloadTest < ActiveSupport::TestCase
  test 'initializes default period' do
    # Make sure initialization does not break as we specify a period in the example below
    report
  end

  test 'collects stats' do
    Fabricate(
      :ordertime,
      hours: 2,
      work_item: work_items(:webauftritt),
      employee: employees(:lucien),
      work_date: worked_at
    )
    Fabricate(
      :ordertime,
      hours: 3,
      work_item: work_items(:hitobito_demo_app),
      employee: employees(:lucien),
      work_date: worked_at
    )

    Fabricate(
      :ordertime,
      hours: 3,
      work_item: work_items(:hitobito_demo_app),
      employee: employees(:lucien),
      work_date: worked_at - 1.week
    )

    stats = report.stats

    assert_equal 4, stats.length

    assert_includes(
      stats,
      {
        name: 'workload',
        fields: {
          employment_fte: 0.0,
          must_hours: 0,
          ordertime_hours: 5.0,
          paid_absence_hours: 0,
          worktime_balance: 5.0,
          external_client_hours: 2.0,
          billable_hours: 2.0,
          workload: 40.0,
          billability: 100.0,
          absolute_billability: 40.0
        },
        tags: { department: 'devtwo', week: 'CW 26' }
      }
    )

    assert_includes(
      stats,
      {
        name: 'workload',
        fields: {
          employment_fte: 0.0,
          must_hours: 0,
          ordertime_hours: 8.0,
          paid_absence_hours: 0,
          worktime_balance: 8.0,
          external_client_hours: 2.0,
          billable_hours: 2.0,
          workload: 25.0,
          billability: 100.0,
          absolute_billability: 25.0
        },
        tags: { department: 'devtwo', month: '2021-06' }
      }
    )
  end

  private

  def report
    # The work items are the last week of June (CW 26), the report runs in the first week of July (CW 27)
    @report = Reports::BIWorkload.new(worked_at + 1.week)
  end

  def worked_at
    @worked_at ||= Date.new(2_021, 6, 28) # A monday
  end

  def create_employments
    Fabricate(
      :employment,
      employee: employees(:pascal),
      start_date: Date.parse('1.1.2006'),
      percent: 80
    )
    Fabricate(
      :employment,
      employee: employees(:lucien),
      start_date: Date.parse('1.1.2006'),
      percent: 100
    )
  end
end
