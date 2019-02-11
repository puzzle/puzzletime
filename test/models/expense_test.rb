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

end
