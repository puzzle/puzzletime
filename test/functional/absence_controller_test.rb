require File.dirname(__FILE__) + '/../test_helper'
require 'absence_controller'

# Re-raise errors caught by the controller.
class AbsenceController; def rescue_action(e) raise e end; end

class AbsenceControllerTest < Test::Unit::TestCase
  def setup
    @controller = AbsenceController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
