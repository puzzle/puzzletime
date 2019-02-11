require 'test_helper'

class ExpenseTest < ActiveSupport::TestCase

  test 'status_value returns translated value' do
    assert_equal 'Offen', Expense.new.status_value
  end

  test 'kind_value returns translated value' do
    assert_equal 'Aus- / Weiterbildung', Expense.new(kind: :training).kind_value
  end

  test 'to_s returns kind_value' do
    assert_equal 'Aus- / Weiterbildung', Expense.new(kind: :training).to_s
  end

  test '.by_month returns models grouped by month' do
    hash = Expense.by_month(Expense.list, 2019)
    assert_equal ['Januar, 2019', 'Februar, 2019'], hash.keys
  end

  test "pascal can manage pascal's invoices" do
    assert can?(:manage, pascal, pascal.expenses.build)
  end

  test "pascal can not manage mark's invoices" do
    refute can?(:manage, pascal, mark.expenses.build)
  end

  test "mark can manage pascal's invoices" do
    assert can?(:manage, mark, pascal.expenses.build)
  end

  test '.reimbursement_months returns single date for each reimbursement year / month combination' do
    assert_equal [Date.new(2019, 1, 1)], Expense.reimbursement_months

    expenses(:approved).update!(reimbursement_date: Date.new(2019, 1, 28))
    assert_equal [Date.new(2019, 1, 1)], Expense.reimbursement_months

    expenses(:pending).update!(reimbursement_date: Date.new(2019, 2, 28))
    assert_equal [Date.new(2019, 1, 1), Date.new(2019, 2, 1)], Expense.reimbursement_months
  end

  test '.payment_years returns single date for each payment year combination' do
    assert_equal [Date.new(2019, 1, 1)], Expense.payment_years(pascal)

    expenses(:approved).update!(payment_date: Date.new(2019, 2, 28))
    assert_equal [Date.new(2019, 1, 1)], Expense.payment_years(pascal)

    expenses(:pending).update!(payment_date: Date.new(2020, 2, 28))
    assert_equal [Date.new(2019, 1, 1), Date.new(2020, 1, 1)], Expense.payment_years(pascal)
  end

  def mark
    employees(:mark)
  end

  def pascal
    employees(:pascal)
  end

  def can?(action, employee, expense)
    Ability.new(employee).can?(action, expense)
  end

end
