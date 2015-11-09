# encoding: utf-8

class OrderReportsController < ApplicationController

  include DryCrud::Rememberable

  self.remember_params = %w(start_date end_date department_id client_work_item_id
                            category_work_item_id kind_id status_id responsible_id target)


  before_action :authorize_class

  def index
    set_period
    set_filter_values
    @report = Order::Report.new(params)
  end

  private

  def set_filter_values
    @departments = Department.list
    @clients = WorkItem.joins(:client).list
    @categories = [] # TODO
    @order_kinds = OrderKind.list
    @order_status = OrderStatus.list
    @order_responsibles = Employee.joins(:managed_orders).uniq.list
    @target_scopes = TargetScope.list
    @order_targets = [] # TODO
  end

  def set_period
    @period = Period.retrieve(params[:start_date].presence,
                              params[:end_date].presence)
    fail ArgumentError, 'Start Datum nach End Datum' if @period.negative?
    @period
  rescue ArgumentError => ex
    # from Period.retrieve or if period.negative?
    flash.now[:alert] = "Ungültige Zeitspanne: #{ex}"
    @period = Period.new(nil, nil)

    params.delete(:start_date)
    params.delete(:end_date)
    @period
  end

  def authorize_class
    authorize!(:reports, Order)
  end


end
