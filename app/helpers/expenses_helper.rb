# frozen_string_literal: true

module ExpensesHelper
  def format_expense_status_value(expense)
    memo = Expense.statuses.keys.zip(%w(info warning success danger)).to_h
    content_tag(:span, expense.status_value, class: "label label-#{memo[expense.status]}")
  end

  def format_expense_amount(expense)
    safe_join([f(expense.amount), currency], ' ')
  end

  def expense_details_col(table, personal: true)
    table.col('', class: 'right') do |e|
      path = personal ? employee_expense_path(e.employee, e) : expense_path(e)
      link_to(path, title: 'Details') do
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

        link_to(expenses_review_path(e), title: 'Kontrollieren') do
          tag.i(class: 'icon-edit') + ' Kontrollieren'
        end

      end
    end
  end

  def expenses_pdf_export_path
    filter_params = params.permit(*controller.class.remember_params)

    expenses_reviews_path(filter_params.merge(format: :pdf))
  end

  def expenses_reimbursement_dates
    [['', 'Bitte wählen Sie einen Monat']] +
      [1, 0, -1, -2].collect do |months_ago|
        date = months_ago.months.ago.end_of_month.to_date
        [date, I18n.l(date, format: :month)]
      end
  end

  def expenses_submission_field(form, small: false)
    date =
      if entry.new_record? || entry.rejected?
        Time.zone.today
      else
        entry.submission_date
      end

    options = {}
    options[:span] = 3 if small

    form.labeled(:submission_date, options) do
      form.string_field(:submission_date, value: I18n.l(date), disabled: true)
    end
  end

  def expenses_order_field(form, small: false)
    options = {
      name: 'expense[order_id]',
      placeholder: 'Suchen...',
      autocomplete: 'off',
      class: entry.new_record? ? 'initial-focus' : '',
      required: true,
      data: {
        autocomplete: 'work_item',
        url: search_orders_path(only_open: true)
      }
    }
    options.merge(span: 10) if small

    form.labeled(:order_id, required: true) do
      select_tag('expense_order_id', work_item_option(@expense&.order), options)
    end
  end

  def expenses_file_field(form, small: false)
    # Due to inconsistent browser behaviour, we need both file endings
    # and the 'all images' mimetype
    file_types = %w(.jpg .jpeg .png).join(',')
    options = {}
    options[:span] = 10 if small

    safe_join(
      [
        form.labeled(:receipt) do
          safe_join(
            [
              content_tag(:div, 'Bitte wählen Sie ein Bild aus', id: 'file_warning', class: 'text-danger hidden'),
              form.file_field(:receipt, options.merge(required: !entry.receipt.attached?, accept: file_types))
            ]
          )
        end,
        form.labeled(' ', options) { t('expenses.attachment.hint') }
      ]
    )
  end

end
