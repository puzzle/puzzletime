#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class WorkloadReportControllerTest < ActionController::TestCase
  setup :login

  test 'GET index without params sets default period' do
    travel_to Time.now.at_noon do
      get :index
      period = assigns(:report).period

      assert_equal(Date.today.prev_month.beginning_of_month, period.start_date)
      assert_equal(Date.today.prev_month.end_of_month, period.end_date)
    end
  end

  test 'GET index without department has empty report' do
    get :index

    assert_equal false, assigns(:report).filters_defined?
  end

  test 'GET index with department and period filter params sets correct report attributes' do
    set_period start_date: '1.1.2006', end_date: '31.12.2006'
    get :index, params: { department_id: departments(:devtwo).id }

    assert_equal true, assigns(:report).filters_defined?
    assert_equal Date.parse('1.1.2006'), assigns(:report).period.start_date
    assert_equal Date.parse('31.12.2006'), assigns(:report).period.end_date
    assert_equal departments(:devtwo), assigns(:report).department
  end
end
