require File.dirname(__FILE__) + '/../test_helper'
require 'planning_controller'

class PlanningControllerTest < ActionController::TestCase
  
  def setup
    @controller = PlanningController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    login_as (:mark)
  end
  
  def test_show_index
    get :index
    assert_redirected_to :action => 'my_planning'
  end

  def test_my_planning
    get :my_planning
    assert_template 'employee_planning'
    
    graph = assigns(:graph)
    assert_not_nil graph
    assert graph.kind_of?(EmployeePlanningGraph)
    assert_equal employees(:mark), graph.employee
    assert_equal 0, graph.plannings.size
  end
  
  def test_existing
    get :existing, :employee_id => employees(:lucien)
    assert_template 'existing'
  end
  
  def test_employee_planning
    get :employee_planning, :employee_id => employees(:lucien)
    assert_template 'employee_planning'
  end
  
  def test_show_add_form
    get :add, :employee_id => employees(:lucien)
    assert_template 'add'
  end
  
  def test_create
    get :add
    
    description = 'new planning description'
    post :create, :planning => {:employee_id => employees(:lucien),
                                :project_id => projects(:puzzletime),
                                :start_week_date => "2010 01",
                                :repeat_type => 'no',
                                :monday_am => '1',
                                :description => description }
    assert_equal description, assigns(:planning).description
    assert_redirected_to :action => 'employee_planning'
  end
  
  def test_create_empty
    get :add
    post :create, :planning => {:employee_id => employees(:lucien), :project_id => projects(:puzzletime)}
    assert_nil assigns(:planning).id
    assert_template 'add'
  end
  
  def test_delete
    post :create, :planning => {:employee_id => employees(:lucien),
                                :project_id => projects(:puzzletime),
                                :start_week_date => "2010 01",
                                :repeat_type => 'no',
                                :monday_am => '1',
                                :description => 'description' }
    assert_not_nil assigns(:planning)
    assert Planning.exists?(assigns(:planning))
    post :delete, :planning => assigns(:planning)
    assert !Planning.exists?(assigns(:planning))
    assert_redirected_to :action => 'employee_planning'
  end
  
  def test_company_planning
    get :company_planning
    assert_template 'company_planning'
  end
  
  def test_department_planning
    get :department_planning, :department_id => departments(:devone)
    assert_template 'department_planning'
  end
  
  def test_project_planning
    get :project_planning, :project_id => projects(:allgemein)
    assert_template 'project_planning'

  end

  def test_projects
    get :projects
    assert_template 'projects'
  end
  
  def test_departments
    get :departments
    assert_template 'departments'
  end

end
