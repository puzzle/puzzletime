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

  test 'PUT#update redirects to expense_review if review param is set' do
    expense = expenses(:pending)

    login_as(:mark)
    put :update, params: { employee_id: expense.employee_id, id: expense.id, review: 1, expense: { amount: 1 } }
    assert_equal 1, expense.reload.amount
    assert_redirected_to expense_review_path(expense)
  end

  %w(pending undecided rejected).each do |status|
    test "PUT#update employee may update #{status} expense" do
      expense = expenses(status)

      login_as(:pascal)
      put :update, params: { employee_id: expense.employee_id, id: expense.id, expense: { amount: 1 } }
      assert_equal 1, expense.reload.amount
      assert expense.pending? if status == 'rejected'
    end

    test "DELETE#destroy employee may destroy #{status} expense" do
      expense = expenses(status)

      login_as(:pascal)
      assert_difference 'Expense.count', -1 do
        delete :destroy, params: { employee_id: expense.employee_id, id: expense.id }
      end
    end
  end

  test 'PUT#update employee may not update approved expense' do
    expense = expenses(:approved)

    login_as(:pascal)
    put :update, params: { employee_id: expense.employee_id, id: expense.id, expense: { amount: 1 } }
    refute_equal 1, expense.reload.amount
    assert_redirected_to employee_expenses_path(expense.employee)
    assert_equal 'Freigegebene Spesen können nicht verändert werden.', flash[:alert]
  end

  test "DELETE#destroy employee may not destroy approved expense" do
    expense = expenses(:approved)

    login_as(:pascal)
    assert_no_difference 'Expense.count', -1 do
      delete :destroy, params: { employee_id: expense.employee_id, id: expense.id }
      assert_redirected_to employee_expenses_path(expense.employee)
      assert_equal 'Freigegebene Spesen können nicht verändert werden.', flash[:alert]
    end
  end

  test 'PUT#update management may update approved expense' do
    expense = expenses(:approved)

    login_as(:mark)
    put :update, params: { employee_id: expense.employee_id, id: expense.id, expense: { amount: 1 } }
    assert_equal 1, expense.reload.amount
  end

  test 'DELETE#destroy employee may delete approved expense' do
    expense = expenses(:approved)

    login_as(:mark)
      assert_difference 'Expense.count', -1 do
        delete :destroy, params: { employee_id: expense.employee_id, id: expense.id, expense: { amount: 1 } }
      end
  end

  test 'GET#index.pdf employee may export a pdf' do
    login_as(:pascal)
    get :index, params: { employee_id: employees(:pascal).id, format: :pdf}
    assert_equal 4, assigns(:expenses).count
    assert_equal 'application/pdf', response.headers['Content-Type']
    assert_equal 'inline; filename="expenses.pdf"', response.headers['Content-Disposition']
  end
end
