require 'test_helper'

class ExpensesControllerTest < ActionController::TestCase

  setup :login

  test 'GET#index management may list all expenses' do
    login_as(:mark)
    get :index
    assert_equal 3, assigns(:expenses).count
  end

  test 'GET#index management may filter by status' do
    login_as(:mark)
    get :index, params: { status: :pending }
    assert_equal 1, assigns(:expenses).count
  end

  test 'GET#index management may filter by employee_id' do
    login_as(:mark)
    get :index, params: { employee_id: employees(:pascal).id }
    assert_equal 2, assigns(:expenses).count
  end

  test 'GET#index management may filter by department_id' do
    login_as(:mark)
    employees(:pascal).update(department: departments(:devone))
    get :index, params: { department_id: departments(:devone).id }
    assert_equal 2, assigns(:expenses).count
  end

  test 'GET#index management may filter by reimbursement_date' do
    login_as(:mark)
    get :index, params: { reimbursement_date: '2019_01' }
    assert_equal 2, assigns(:expenses).count
  end

  test 'GET#index employee may not list top level expenses' do
    login_as(:pascal)
    assert_raise { get :index }
  end

  test 'GET#index employee may list his expenses' do
    login_as(:pascal)
    get :index, params: { employee_id: employees(:pascal).id }
    assert_equal 2, assigns(:expenses).count
  end

  test 'GET#index employee may filter by payment_date' do
    login_as(:pascal)
    get :index, params: { employee_id: employees(:pascal).id, payment_date: 2018 }
    assert_equal 0, assigns(:expenses).count
  end


end
