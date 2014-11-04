class OrderServicesController < ApplicationController

  include Filterable
  include DryCrud::Rememberable

  self.remember_params = %w(employee_id work_item_id billable)

  before_action :order
  before_action :authorize_class
  before_filter :handle_remember_params, only: [:show]
  before_action :set_filter_values, only: :show

  def show
    @worktimes = list_worktimes
  end

  def edit

  end

  def update

  end

  private

  def list_worktimes
    entries = order.worktimes.includes(:employee, :work_item).order(:work_date)
    filter_entries_by(entries, :employee_id, :work_item_id, :billable)
  end

  def order
    @order ||= Order.find(params[:order_id])
  end

  def set_filter_values
    @employees = Employee.where(id: order.worktimes.select(:employee_id)).list
    @accounting_posts = order.work_item.self_and_descendants.leaves.list
  end

  def authorize_class
    authorize!(:services, order)
  end

end