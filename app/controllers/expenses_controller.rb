class ExpensesController < ManageController
  include Filterable
  self.optional_nesting = [Employee]

  self.permitted_attrs = [:payment_date, :employee_id, :kind, :order_id, :description, :amount, :receipt]
  self.remember_params += %w(status)

  before_render_index :populate_management_filter_selects, unless: :parent
  before_render_index :populate_employee_filter_selects, if: :parent
  before_render_form :populate_orders
  before_action :set_payment_date, only: :index, if: :parent
  before_action :approved_expenses, only: [:edit, :destroy] # rubocop:disable Rails/LexicallyScopedActionFilter

  def new
    super
    if params[:template]
      template = Expense.find_by(id: params[:template])
      if template
        @expense.kind         = template.kind
        @expense.amount       = template.amount
        @expense.payment_date = template.payment_date
        @expense.description  = template.description
        @expense.order_id     = template.order_id
      end
    end
  end

  def update
    super
    if entry.employee == current_user && entry.rejected?
      entry.pending!
    end
  end

  def export
    entries = params['entries'].split(',').map(&:to_i).compact
    entries.delete(0)
    send_file Expenses::PdfExport.new(entries).generate, disposition: :inline
  end

  private

  def list_entries
    entries = parent ? super : super.joins(:employee).includes(:employee, :reviewer)
    entries = filter_entries_by(entries, :status, :employee_id)
    entries = filter_by_date(entries, :reimbursement_date, :all_month, /(\d{4})_(\d{2})/)
    entries = filter_by_date(entries, :payment_date, :all_year, /(\d{4})/)
    filter_by_department(entries)
  end

  def filter_by_date(scope, key, date_method, regex)
    return scope unless regex.match(params[key])

    year, month = *Regexp.last_match.captures.collect(&:to_i)
    scope.where(key => Date.new(year, month || 1, 1).send(date_method))
  end

  def filter_by_department(scope)
    return scope if params[:department_id].blank?

    scope.where(employees: { department_id: params[:department_id] })
  end

  def populate_management_filter_selects
    @employees = Employee.joins(:expenses).list.uniq
    @departments = Department.list.joins(:employees).where(employees: { id: @employees })
    @statuses = Expense.statuses.collect { |key, value| IdValue.new(value, Expense.status_value(key)) }
    @kinds = Expense.kinds.collect { |key, value| IdValue.new(value, Expense.kind_value(key)) }
    @months = Expense.reimbursement_months.sort.reverse.collect do |date|
      IdValue.new(I18n.l(date, format: '%Y_%m'), I18n.l(date, format: '%B, %Y'))
    end
    @filtered_expenses = list_entries.except(:limit, :offset).pluck(:id)
  end

  def populate_employee_filter_selects
    @years = Expense.payment_years(parent).sort.reverse.collect do |date|
      IdValue.new(I18n.l(date, format: '%Y'), I18n.l(date, format: '%Y'))
    end
  end

  def set_payment_date
    params[:payment_date] ||= list_entries.maximum(:payment_date)&.year.to_s
  end

  def populate_orders
    @orders = Order.list.open.collect { |o| IdValue.new(o.id, o.label_with_workitem_path) }
  end

  def authorize_class
    authorize!(:new, Expense.new(employee: parent))
  end

  def approved_expenses
    msg = 'Freigegebene Spesen können nicht bearbeitet oder gelöscht werden.'
    redirect_to(:back, alert: msg) if entry.approved?
  rescue RedirectBackError
    redirect_to(employee_expense_path(employee), alert: msg)
  end

end
