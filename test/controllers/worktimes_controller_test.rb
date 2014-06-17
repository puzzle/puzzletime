require 'test_helper'

class WorktimesControllerTest < ActionController::TestCase

  def test_index
    get :index
    assert_response :success
  end

end
