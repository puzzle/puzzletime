# frozen_string_literal: true

# {{{
# == Schema Information
#
# Table name: expenses
#
#  id                 :bigint           not null, primary key
#  amount             :decimal(12, 2)   not null
#  description        :text             not null
#  kind               :integer          not null
#  payment_date       :date             not null
#  reason             :text
#  reimbursement_date :date
#  reviewed_at        :datetime
#  status             :integer          default("pending"), not null
#  submission_date    :date
#  employee_id        :bigint           not null
#  order_id           :bigint
#  reviewer_id        :bigint
#
# Indexes
#
#  index_expenses_on_employee_id  (employee_id)
#  index_expenses_on_order_id     (order_id)
#  index_expenses_on_reviewer_id  (reviewer_id)
#  index_expenses_on_status       (status)
#
# }}}

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

    assert_equal ['Februar 2019', 'Januar 2019'], hash.keys
  end

  test "pascal can manage pascal's invoices" do
    assert can?(:manage, pascal, pascal.expenses.build)
  end

  test "pascal can not manage mark's invoices" do
    assert_not can?(:manage, pascal, mark.expenses.build)
  end

  test "mark can manage pascal's invoices" do
    assert can?(:manage, mark, pascal.expenses.build)
  end

  test '.reimbursement_months returns single date for each reimbursement year / month combination' do
    assert_equal [Date.new(2019, 2, 1), Date.new(2019, 3, 1)], Expense.reimbursement_months

    expenses(:approved).update!(reimbursement_date: Date.new(2019, 2, 1))

    assert_equal [Date.new(2019, 2, 1)], Expense.reimbursement_months
  end

  test '.payment_years returns single date for each payment year combination' do
    assert_equal [Date.new(2019, 1, 1)], Expense.payment_years(pascal)

    expenses(:approved).update!(review_attrs.merge(payment_date: Date.new(2019, 2, 28)))

    assert_equal [Date.new(2019, 1, 1)], Expense.payment_years(pascal)

    expenses(:pending).update!(payment_date: Date.new(2020, 2, 28))

    assert_equal [Date.new(2019, 1, 1), Date.new(2020, 1, 1)], Expense.payment_years(pascal)
  end

  test 'can only approve expense when reimbursement_date and reviewer is set' do
    obj = expenses(:pending)

    assert_not obj.update(status: :approved)
    assert_equal ['Auszahlungsmonat muss ausgefüllt werden', 'Reviewer muss ausgefüllt werden',
                  'Visiert am muss ausgefüllt werden'], obj.errors.full_messages

    assert obj.update(status: :approved,
                      reviewer: mark,
                      reviewed_at: Time.zone.today,
                      reimbursement_date: Time.zone.today)
  end

  def review_attrs
    { reviewer: mark, reviewed_at: Time.zone.today }
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
