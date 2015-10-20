# encoding: UTF-8

require 'test_helper'

class StatusControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_response :success
    assert response.body.include? 'OK'
  end
end
