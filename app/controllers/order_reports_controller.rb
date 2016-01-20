# encoding: utf-8

class OrderReportsController < ApplicationController

  include DryCrud::Rememberable

  self.remember_params = %w(start_date end_date department_id client_work_item_id
                            category_work_item_id kind_id status_id responsible_id target)


  before_action :authorize_class

  def index
    set_period
    @report = Order::Report.new(@period, params)
    respond_to do |format|
      format.html do
        set_filter_values
      end
      format.js do
        set_filter_values
      end
      format.csv do
        send_data(@report.to_csv, type: 'text/csv; charset=utf-8; header=present')
      end
    end
  end

  private

  def set_filter_values
    @departments = Department.list
    @clients = WorkItem.joins(:client).list
    @categories = []
    if params[:client_work_item_id].present?
      @categories = WorkItem.find(params[:client_work_item_id]).categories.list
    end
    @order_kinds = OrderKind.list
    @order_status = OrderStatus.list
    @order_responsibles = Employee.joins(:managed_orders).uniq.list
    @target_scopes = TargetScope.list
  end

  def set_period
    @period = Period.retrieve(params[:start_date].presence,
                              params[:end_date].presence)
    if @period.negative?
      flash.now[:alert] = 'Ungültige Zeitspanne: Start Datum nach End Datum'
      fail ArgumentError
    end
    @period
  rescue ArgumentError => _
    flash.now[:alert] ||= 'Ungültiges Datum'
    @period = Period.new(nil, nil)

    params.delete(:start_date)
    params.delete(:end_date)
    @period
  end

  def authorize_class
    authorize!(:reports, Order)
  end

end
