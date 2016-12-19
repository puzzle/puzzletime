require 'test_helper'

class Plannings::CompaniesControllerTest < ActionController::TestCase

  setup :login

  test 'GET #show renders values of all employed employees' do
    get :show
    assert_equal employees(:various_pedro, :next_year_pablo, :long_time_john),
                 assigns(:overview).boards.map(&:employee)
  end

end