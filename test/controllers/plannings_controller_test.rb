# encoding: utf-8

require 'test_helper'

class PlanningsControllerTest < ActionController::TestCase

  setup :login

  def test_show_index
    get :index
    assert_redirected_to action: 'my_planning'
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
    xhr :get, :existing, planning: { employee_id: employees(:lucien) }
    assert_template 'existing'
  end

  def test_employee_planning
    get :employee_planning, employee_id: employees(:lucien)
    assert_template 'employee_planning'
  end

  def test_show_add_form
    get :new, employee_id: employees(:lucien)
    assert_template 'new'
  end

  def test_create
    description = 'new planning description'
    post :create, planning: { employee_id: employees(:lucien),
                              work_item_id: work_items(:puzzletime),
                              start_week_date: '2010 01',
                              repeat_type: 'no',
                              monday_am: '1',
                              description: description }
    assert_equal description, assigns(:planning).description
    assert_redirected_to action: 'employee_planning', employee_id: employees(:lucien)
  end

  def test_create_empty
    post :create, planning: { employee_id: employees(:lucien), work_item_id: work_items(:puzzletime) }
    assert_nil assigns(:planning).id
    assert_template 'new'
  end

  def test_delete
    post :create, planning: { employee_id: employees(:lucien),
                              work_item_id: work_items(:puzzletime),
                              start_week_date: '2010 01',
                              repeat_type: 'no',
                              monday_am: '1',
                              description: 'description' }
    assert_not_nil assigns(:planning)
    assert Planning.exists?(assigns(:planning).id)
    delete :destroy, planning: assigns(:planning)
    assert !Planning.exists?(assigns(:planning).id)
    assert_redirected_to action: 'employee_planning', employee_id: employees(:lucien)
  end

  def test_company_planning
    get :company_planning
    assert_template 'company_planning'
  end

  def test_company_planning_employee_ordering
    get :company_planning
    employee_graphs = assigns(:graph).employee_graphs
    loads = employee_graphs.map(&:period_load)
    assert_equal loads.sort, loads
  end

  def test_department_planning
    get :department_planning, department_id: departments(:devone)
    assert_template 'department_planning'
  end

  def test_work_item_planning
    get :work_item_planning, work_item_id: work_items(:allgemein)
    assert_template 'work_item_planning'
  end

  def test_work_items
    get :work_items
    assert_template 'work_items'
  end

  def test_departments
    get :departments
    assert_template 'departments'
  end

end
