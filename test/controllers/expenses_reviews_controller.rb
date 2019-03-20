require 'test_helper'

class ExpensesReviewsControllerTest < ActionController::TestCase

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

  test 'GET#show employee may not work with expense reviews' do
    login_as(:pascal)
    assert_raise do
      get :show, params: { id: expenses(:pending).id }
    end
  end

  test 'GET#show management may work with expense reviews' do
    login_as(:mark)
    get :show, params: { id: expenses(:pending).id }
    assert_response :success
  end

  test 'GET#show redirects if expense is already processed' do
    login_as(:mark)
    get :show, params: { id: expenses(:payed).id }
    assert_redirected_to expenses_path(returning: true)
    assert_equal 'Projekt wurde bereits bearbeitet', flash[:notice]
  end

  test 'PATCH#update approves expenses and redirects to list' do
    login_as(:mark)
    get :update, params: { id: expenses(:pending).id, expense: { status: :approved, reimbursement_date: '2019-03-01' } }
    assert_redirected_to expenses_reviews_path(returning: true)
    assert_equal "Aus- / Weiterbildung wurde freigegeben.", flash[:notice]
  end

  test 'PATCH#update defers expenses and redirects to list' do
    login_as(:mark)
    get :update, params: { id: expenses(:pending).id, expense: { status: :deferred } }
    assert_redirected_to expenses_reviews_path(returning: true)
    assert_equal "Aus- / Weiterbildung wurde zurückgestellt.", flash[:notice]
  end

  test 'PATCH#update approves expenses and redirects to next open expense if any' do
    login_as(:mark)
    other = Expense.create!(employee: employees(:pascal), payment_date: '2019-02-02', kind: :training, description: 'test',  amount: 1)
    get :update, params: { id: expenses(:pending).id, expense: { status: :approved, reimbursement_date: '2019-03-01' } }
    assert_redirected_to expenses_review_path(other)
  end

  test 'PATCH#create approves expenses and redirects to next open expense if any of status set on list view' do
    login_as(:mark)
    list_params = { '/expenses' => { 'status' => Expense.statuses['deferred'] } }
    other = Expense.create!(employee: employees(:pascal), status: :deferred, payment_date: '2019-02-11', kind: :training, description: 'test', amount: 1)
    get :update, params: { id: expenses(:pending).id, expense: { status: :approved, reimbursement_date: '2019-03-01' } }, session: { 'list_params' => list_params }
    assert_redirected_to expenses_review_path(other)
  end


end
