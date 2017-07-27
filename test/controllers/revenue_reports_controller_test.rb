#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class RevenueReportsControllerTest < ActionController::TestCase

  setup do
    login
    travel_to Date.new(2000, 9, 5)
  end

  teardown do
    travel_back
  end

  test 'sets default period' do
    session[:period] = nil
    get :index
    assert_equal Period.parse('b'), assigns(:period)
  end

  test 'uses limited period' do
    period = Period.parse('-1m')
    session[:period] = [period.start_date, period.end_date, period.label, period.shortcut]
    get :index
    assert_equal period, assigns(:period)
  end

  test 'renders default period with past and future' do
    get :index
    assert_headings 'Organisationseinheit',
                    'Juli 2000', 'August 2000',
                    'Total', '⌀',
                    'September 2000', 'Oktober 2000', 'November 2000', 'Dezember 2000'
  end

  test 'renders past-only period' do
    period = Period.parse('-1y')
    session[:period] = [period.start_date, period.end_date, period.label, period.shortcut]
    get :index
    assert_headings 'Organisationseinheit',
                    'Januar 1999', 'Februar 1999', 'März 1999', 'April 1999', 'Mai 1999',
                    'Juni 1999', 'Juli 1999', 'August 1999', 'September 1999', 'Oktober 1999',
                    'November 1999', 'Dezember 1999',
                    'Total', '⌀'
  end

  test 'renders future-only period' do
    period = Period.parse('+1y')
    session[:period] = [period.start_date, period.end_date, period.label, period.shortcut]
    get :index
    assert_headings 'Organisationseinheit',
                    'Januar 2001', 'Februar 2001', 'März 2001', 'April 2001', 'Mai 2001',
                    'Juni 2001', 'Juli 2001', 'August 2001', 'September 2001', 'Oktober 2001',
                    'November 2001', 'Dezember 2001'
  end

  private

  def assert_headings(*expected)
    assert_equal expected, table_headings
  end

  def table_headings
    assert_select('.revenue-report thead th').map { |e| e.text.strip }
  end

end
