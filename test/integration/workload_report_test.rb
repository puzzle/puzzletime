#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class WorkloadReportTest < ActionDispatch::IntegrationTest
  setup :login

  test 'member detail links are set-up on first page load' do
    find('a[data-toggle="employee-8-ordertimes"]').click
    assert_selector 'tbody#employee-8-ordertimes'
  end

  test 'member detail links are set-up after changing filter' do
    set_period

    assert_no_selector 'tbody#employee-6-ordertimes'
    find('a[data-toggle="employee-6-ordertimes"]').click
    assert_selector 'tbody#employee-6-ordertimes'
  end

  private

  def login
    login_as(:mark)
    set_period(start_date: '1.1.2006', end_date: '31.12.2006', back_url: '/')
    visit reports_workload_path(department_id: departments(:devtwo).id)
  end
end
