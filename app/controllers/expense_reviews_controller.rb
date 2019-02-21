class ExpenseReviewsController < ApplicationController
  before_action :authorize
  helper_method :entry

  def show
    entry.reimbursement_date = Time.zone.today.end_of_month

    unless entry.pending? || entry.deferred?
      redirect_to expenses_path(returning: true), notice: "#{entry} wurde bereits bearbeitet"
    end
  end

  def create
    updated = entry.update(attributes)

    if updated
      redirect_to redirect_path, notice: message
    else
      render :show
    end
  end

  private

  def entry
    @entry ||= Expense.find(params[:expense_id])
  end

  def authorize
    authorize!(:manage, Expense.new)
  end

  def attributes
    attrs = params.require(:expense).permit(:status, :reimbursement_date, :rejection)
    attrs = attrs[:status] == 'approved' ? attrs.except(:rejection) : attrs.except(:reimbursement_date)
    attrs.merge(reviewer: current_user, reviewed_at: Time.zone.now)
  end

  def status
    value = session.to_h.dig('list_params', '/expenses', 'status').presence
    Expense.statuses.invert[value.to_i] || :pending
  end

  def next_expense
    @next_expense ||= Expense.list.send(status).first
  end

  def redirect_path
    next_expense ? expense_review_path(next_expense) : expenses_path(returning: true)
  end

  def message
    state_change = entry.deferred? ? 'zurückgestellt' : entry.status_value.downcase
    "#{entry} wurde #{state_change}."
  end

end
