# frozen_string_literal: true

class ExpensesReviewsController < ManageController
  include Filterable

  delegate :model_class,      to: 'self.class'
  delegate :controller_class, to: 'self.class'

  helper_method :model_class, :controller_class, :review_list

  def self.model_class;      Expense; end
  def self.controller_class; Expense; end

  self.permitted_attrs = [:payment_date, :employee_id, :kind, :order_id, :description, :amount, :receipt]
  self.remember_params += %w(status employee_id reimbursement_date department_id)

  skip_authorize_resource
  before_action :authorize
  before_render_index :populate_management_filter_selects
  before_render_form :populate_orders

  def index
    respond_to do |format|
      format.any
      format.pdf { send_file Expenses::PdfExport.new(entries).generate, disposition: :inline }
    end
  end

  def show
    unless entry.pending? || entry.deferred?
      redirect_to expenses_path(returning: true), notice: "#{entry} wurde bereits bearbeitet"
    end
  end

  def update
    updated = entry.update(attributes)

    if updated
      redirect_to redirect_path, notice: message
    else
      render :show
    end
  end

  private

  def list_entries
    entries = parent ? super.includes(:reviewer) : super.joins(:employee).includes(:employee, :reviewer)
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
    @employees   = Employee.joins(:expenses).list.uniq
    @departments = Department.list.joins(:employees).where(employees: { id: @employees }).uniq
    @statuses    = Expense.statuses.collect { |key, value| IdValue.new(value, Expense.status_value(key)) }
    @kinds       = Expense.kinds.collect { |key, value| IdValue.new(value, Expense.kind_value(key)) }
    @months      = Expense.reimbursement_months.sort.reverse.collect do |date|
      IdValue.new(I18n.l(date, format: '%Y_%m'), I18n.l(date, format: '%B, %Y'))
    end
    @filtered_expenses = list_entries.except(:limit, :offset).pluck(:id)
  end

  def populate_orders
    @orders = Order.list.open.collect { |o| IdValue.new(o.id, o.label_with_workitem_path) }
  end

  def authorize
    authorize!(:manage, Expense.new)
  end

  def attributes
    attrs = params.require(:expense).permit(:status, :reimbursement_date, :reason)
    attrs = attrs.except(:reimbursement_date) if attrs[:status] == 'rejected'
    attrs.merge(reviewer: current_user, reviewed_at: Time.zone.now)
  end

  def status
    value = session.to_h.dig('list_params', '/expenses', 'status').presence
    Expense.statuses.invert[value.to_i] || :pending
  end

  def review_list
    Expense.list.send(status)
  end

  def next_expense
    @next_expense ||= review_list.first
  end

  def redirect_path
    next_expense ? expenses_review_path(next_expense) : expenses_reviews_path(returning: true)
  end

  def message
    state_change = entry.deferred? ? 'zurückgestellt' : entry.status_value.downcase
    "#{entry} wurde #{state_change}."
  end

end
