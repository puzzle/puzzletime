# -*- coding: utf-8 -*-

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

  test 'only management and order responsible employees have access' do
    management        = Ability.new(employees(:mark))
    order_responsible = Ability.new(employees(:lucien))
    normal_user       = Ability.new(employees(:pascal))

    assert management.can?(:revenue_reports, Department)
    assert order_responsible.can?(:revenue_reports, Department)
    assert normal_user.cannot?(:revenue_reports, Department)
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

  test 'GET index csv exports csv file with grouping: Department' do
    get :index, params: { grouping: 'Department' }, format: :csv
    csv_match 'Organisationseinheit', response.body
  end

  test 'GET index csv exports csv file with grouping: PortfolioItem' do
    get :index, params: { grouping: 'PortfolioItem' }, format: :csv
    csv_match 'Portfolioposition', response.body
  end

  test 'GET index csv exports csv file with grouping: Service' do
    get :index, params: { grouping: 'Service' }, format: :csv
    csv_match 'Dienstleistung', response.body
  end

  test 'GET index csv exports csv file with grouping: Sector' do
    get :index, params: { grouping: 'Sector' }, format: :csv
    csv_match 'Branche', response.body
  end

  private

  def assert_headings(*expected)
    assert_equal expected, table_headings
  end

  def table_headings
    assert_select('.revenue-report thead th').map { |e| e.text.strip }
  end

  def csv_match(grouping, body)
    assert_match(/#{grouping}/,                              body) # grouping
    assert_match(/Juli 2000,August 2000/,                    body) # past months
    assert_match(/Total,⌀/,                                  body) # past months summary
    assert_match(/September 2000/,                           body) # current month
    assert_match(/Oktober 2000,November 2000,Dezember 2000/, body) # future months
    assert_match(/Total,0,0,0,0,0,0,0,0/,                    body) # summary footer
  end
end
