class ExpenseReviewsController < ApplicationController
  before_action :authorize
  helper_method :entry, :build_reimbursement_dates

  def show
    unless entry.pending? || entry.undecided?
      redirect_to expenses_path(returning: true), notice: "#{entry} wurde bereits bearbeitet"
    end
  end

  def create
    updated = entry.update(attributes)

    if updated && next_expense
      message = "#{entry} wurde #{entry.status_value.downcase}."
      redirect_to expense_review_path(expense_id: next_expense.id), notice: message
    elsif updated
      message = "Keine weiteren Einträge im status '#{Expense.status_value(status)}'."
      redirect_to expenses_path(returning: true), notice: message
    else
      render :show
    end
  end

  def update
    entry.update(edit_attributes)
    render :show
  end

  private

  def entry
    @entry ||= Expense.find(params[:expense_id])
  end

  def authorize
    authorize!(:manage, Expense.new)
  end

  def build_reimbursement_dates
    [2, 1, 0, -1].collect do |months_ago|
      date = months_ago.months.ago.end_of_month.to_date
      [date, I18n.l(date, format: :month)]
    end
  end

  def attributes
    attrs = params.require(:expense).permit(:status, :reimbursement_date, :rejection)
    attrs = attrs[:status] == 'approved' ? attrs.except(:rejection) : attrs.except(:reimbursement_date)
    attrs.merge(reviewer: current_user, reviewed_at: Time.zone.now)
  end

  def edit_attributes
    params.require(:expense).permit(:payment_date, :employee_id, :amount, :kind, :description, :receipt)
  end

  def status
    value = session.to_h.dig('list_params', '/expenses', 'status').presence
    Expense.statuses.invert[value.to_i] || :pending
  end

  def next_expense
    @next_expense ||= Expense.list.send(status).first
  end

end
