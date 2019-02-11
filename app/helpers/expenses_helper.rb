module ExpensesHelper
  def format_expense_status_value(expense)
    memo = Expense.statuses.keys.zip(%w(info success warning)).to_h
    content_tag(:span, expense.status_value, class: "label label-#{memo[expense.status]}")
  end

  def format_expense_amount(expense)
    safe_join([f(expense.amount), currency], ' ')
  end
end
