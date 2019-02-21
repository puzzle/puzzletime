require 'test_helper'

class ExpensesControllerTest < ActionController::TestCase

  setup :login

  test 'GET#index management may list all expenses' do
    login_as(:mark)
    get :index
    assert_equal 5, assigns(:expenses).count
  end

  test 'GET#index management may filter by status' do
    login_as(:mark)
    get :index, params: { status: :pending }
    assert_equal 1, assigns(:expenses).count
  end

  test 'GET#index management may filter by employee_id' do
    login_as(:mark)
    get :index, params: { employee_id: employees(:pascal).id }
    assert_equal 4, assigns(:expenses).count
  end

  test 'GET#index management may filter by department_id' do
    login_as(:mark)
    employees(:pascal).update(department: departments(:devone))
    get :index, params: { department_id: departments(:devone).id }
    assert_equal 4, assigns(:expenses).count
  end

  test 'GET#index management may filter by reimbursement_date' do
    login_as(:mark)
    get :index, params: { reimbursement_date: '2019_02' }
    assert_equal 1, assigns(:expenses).count
  end

  test 'GET#index employee may not list top level expenses' do
    login_as(:pascal)
    assert_raise { get :index }
  end

  test 'GET#index employee may list his expenses' do
    login_as(:pascal)
    get :index, params: { employee_id: employees(:pascal).id }
    assert_equal 4, assigns(:expenses).count
  end

  test 'GET#index employee may filter by payment_date' do
    login_as(:pascal)
    get :index, params: { employee_id: employees(:pascal).id, payment_date: 2018 }
    assert_equal 0, assigns(:expenses).count
  end

  test 'GET#new does not assign value if id does not exists' do
    login_as(:pascal)
    get :new, params: { employee_id: employees(:pascal).id, template: -1 }
    assert_nil assigns(:expense).kind
  end

  test 'GET#new assigns attributes from template' do
    expense = expenses(:approved)
    expense.update!(description: 'train ticket')

    login_as(:pascal)
    get :new, params: { employee_id: expense.employee_id, template: expense.id }
    assert assigns(:expense).project?
    assert assigns(:expense).pending?
    assert_equal 32, assigns(:expense).amount
    assert_equal 'train ticket', assigns(:expense).description
    assert_equal Date.new(2019, 2, 10), assigns(:expense).payment_date
  end

  test 'PATCH#update reverts status to approved if a rejected expense is edited' do
    login_as(:pascal)
    expense = expenses(:rejected)
    patch :update,
      params: {
      id: expense.id,
      expense: { description: 'after test' }
    }
    assert 'pending', expense.reload.status
    assert 'after test', expense.reload.description
  end

  test 'GET#index.pdf employee may export a pdf' do
    login_as(:pascal)
    get :index, params: { employee_id: employees(:pascal).id, format: :pdf}
    assert_equal 4, assigns(:expenses).count
    assert_equal 'application/pdf', response.headers['Content-Type']
    assert_equal 'inline; filename="expenses.pdf"', response.headers['Content-Disposition']
  end
end
