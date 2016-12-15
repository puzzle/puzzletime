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

    period = Period.parse('-1m')
    session[:period] = [period.start_date, period.end_date, period.label, period.shortcut]
    get :index
    assert_equal period, assigns(:period)
  end

end
