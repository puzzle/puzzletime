require 'test_helper'

class AbsencetimesControllerTest < ActionController::TestCase
  
  setup :login
  
  def test_new
    get :new
    assert_not_nil assigns(:worktime)
  end
  
  def test_new_with_template
    template = worktimes(:wt_pz_vacation)
    template.update_attributes(description: "desc")
    
    get :new, template: template.id
    assert_equal template.absence, assigns(:worktime).absence
    assert_equal "desc", assigns(:worktime).description
  end

  
end
