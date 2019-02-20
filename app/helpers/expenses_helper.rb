module ExpensesHelper
  def format_expense_status_value(expense)
    memo = Expense.statuses.keys.zip(%w(info warning success danger)).to_h
    content_tag(:span, expense.status_value, class: "label label-#{memo[expense.status]}")
  end

  def format_expense_amount(expense)
    safe_join([f(expense.amount), currency], ' ')
  end

  def expense_duplicate_col(table)
    table.action_col do |e|
      link_to(new_employee_expense_path(e.employee, template: e), title: 'Kopieren') do
        if block_given?
          yield(e)
        else
          tag.i(class: 'icon-duplicate')
        end
      end
    end
  end

  def expense_edit_col(table)
    table.action_col do |e|
      next if e.approved?

      table.table_action_link(
        'edit',
        edit_employee_expense_path(e.employee, e),
        title: 'Bearbeiten'
      )
    end
  end

  def expense_destroy_col(table)
    table.action_col do |e|
      next if e.approved?

      table.table_action_link(
        'delete',
        employee_expense_path(e.employee, e),
        title: 'Löschen',
        data: {
          confirm: ti(:confirm_delete),
          method: :delete
        }
      )
    end
  end

end
