require File.dirname(__FILE__) + '/../test_helper'
require 'evaluator_controller'

# Re-raise errors caught by the controller.
class EvaluatorController; def rescue_action(e) raise e end; end

class EvaluatorControllerTest < Test::Unit::TestCase
  def setup
    @controller = EvaluatorController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
