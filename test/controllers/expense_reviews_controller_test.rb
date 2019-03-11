require 'test_helper'

class ExpenseReviewsControllerTest < ActionController::TestCase

  setup :login

  test 'GET#show employee may not work with expense reviews' do
    login_as(:pascal)
    assert_raise do
      get :show, params: { expense_id: expenses(:pending).id }
    end
  end

  test 'GET#show management may work with expense reviews' do
    login_as(:mark)
    get :show, params: { expense_id: expenses(:pending).id }
    assert_response :success
  end

  test 'GET#show redirects if expense is already processed' do
    login_as(:mark)
    get :show, params: { expense_id: expenses(:payed).id }
    assert_redirected_to expenses_path(returning: true)
    assert_equal 'Projekt wurde bereits bearbeitet', flash[:notice]
  end

  test 'POST#create approves expenses and redirects to list' do
    login_as(:mark)
    get :create, params: { expense_id: expenses(:pending).id, expense: { status: :approved, reimbursement_date: '2019-03-01' } }
    assert_redirected_to expenses_path(returning: true)
    assert_equal "Aus- / Weiterbildung wurde freigegeben.", flash[:notice]
  end

  test 'POST#create defers expenses and redirects to list' do
    login_as(:mark)
    get :create, params: { expense_id: expenses(:pending).id, expense: { status: :deferred } }
    assert_redirected_to expenses_path(returning: true)
    assert_equal "Aus- / Weiterbildung wurde zurückgestellt.", flash[:notice]
  end

  test 'POST#create approves expenses and redirects to next open expense if any' do
    login_as(:mark)
    other = Expense.create!(employee: employees(:pascal), payment_date: '2019-02-02', kind: :training, description: 'test',  amount: 1)
    get :create, params: { expense_id: expenses(:pending).id, expense: { status: :approved, reimbursement_date: '2019-03-01' } }
    assert_redirected_to expense_review_path(other)
  end

  test 'POST#create approves expenses and redirects to next open expense if any of status set on list view' do
    login_as(:mark)
    list_params = { '/expenses' => { 'status' => Expense.statuses['deferred'] } }
    other = Expense.create!(employee: employees(:pascal), status: :deferred, payment_date: '2019-02-11', kind: :training, description: 'test', amount: 1)
    get :create, params: { expense_id: expenses(:pending).id, expense: { status: :approved, reimbursement_date: '2019-03-01' } }, session: { 'list_params' => list_params }
    assert_redirected_to expense_review_path(other)
  end

end
