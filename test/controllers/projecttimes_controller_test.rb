require 'test_helper'

class ProjecttimesControllerTest < ActionController::TestCase
  
  setup :login
  
  def test_new
    get :new
    assert_not_nil assigns(:worktime)
  end
  
  def test_show
    worktime = worktimes(:wt_pz_allgemein)
    get :show, id: worktime.id
    assert_redirected_to action: 'index', week_date: worktime.work_date
  end
  
  def test_new_with_template
    template = worktimes(:wt_pz_allgemein)
    template.update_attributes(ticket: "123", description: "desc")
    
    get :new, template: template.id
    assert_equal template.project, assigns(:worktime).project
    assert_equal "123", assigns(:worktime).ticket
    assert_equal "desc", assigns(:worktime).description
  end
  
end
