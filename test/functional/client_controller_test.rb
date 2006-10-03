require File.dirname(__FILE__) + '/../test_helper'
require 'client_controller'

# Re-raise errors caught by the controller.
class ClientController; def rescue_action(e) raise e end; end

class ClientControllerTest < Test::Unit::TestCase
  def setup
    @controller = ClientController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
