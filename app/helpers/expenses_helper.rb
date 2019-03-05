module ExpensesHelper
  def format_expense_status_value(expense)
    memo = Expense.statuses.keys.zip(%w(info warning success danger)).to_h
    content_tag(:span, expense.status_value, class: "label label-#{memo[expense.status]}")
  end

  def format_expense_amount(expense)
    safe_join([f(expense.amount), currency], ' ')
  end

  def expense_details_col(table)
    table.col('', class: 'right') do |e|
      link_to(employee_expense_path(e.employee, e), title: 'Details') do
        tag.i(class: 'icon-document') + ' Details'
      end
    end
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

  def expense_review_col(table)
    table.action_col do |e|
      if e.pending? || e.deferred?

        link_to(expense_review_path(e), title: 'Kontrollieren') do
          tag.i(class: 'icon-edit') + ' Kontrollieren'
        end

      end
    end
  end

  def expenses_pdf_export_path
    filter_params = params.permit(*controller.class.remember_params)

    expenses_path(filter_params.merge(format: :pdf))
  end

  def expenses_reimbursement_dates
    [2, 1, 0, -1].collect do |months_ago|
      date = months_ago.months.ago.end_of_month.to_date
      [date, I18n.l(date, format: :month)]
    end
  end

  def expenses_submission_field(form)
    date =
      if entry.new_record? || entry.rejected?
        Time.zone.today
      else
        entry.submission_date
      end

    form.labeled(:submission_date) do
      form.string_field(:submission_date, value: I18n.l(date), disabled: true)
    end
  end

  def expenses_order_field(form)
    form.labeled(:order_id, required: true) do
      select_tag(
        'expense_order_id',
        work_item_option(@expense&.order),
        name: 'expense[order_id]',
        placeholder: 'Suchen...',
        autocomplete: 'off',
        class: entry.new_record? ? 'initial-focus' : '',
        required: true,
        data: {
          autocomplete: 'work_item',
          url: search_orders_path(only_open: true)
        }
      )
    end
  end

  def expenses_file_field(form)
    safe_join(
      [
        form.labeled_file_field(:receipt, required: !entry.receipt.attached?),
        form.labeled(' ') { t('expenses.attachment.hint') }
      ]
    )
  end

end
