class OrderServicesController < ApplicationController

  before_action :order
  before_action :authorize_class

  def show
    list_worktimes
  end

  def edit

  end

  def update

  end

  private

  def list_worktimes
    @worktimes = order.worktimes.includes(:employee, :work_item).order(:work_date)
  end

  def order
    @order ||= Order.find(params[:order_id])
  end

  def authorize_class
    authorize!(:services, order)
  end

end