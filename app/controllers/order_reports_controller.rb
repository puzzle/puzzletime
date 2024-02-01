#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class OrderReportsController < ApplicationController
  include DryCrud::Rememberable
  include WithPeriod

  self.remember_params = %w[start_date end_date department_id
                            client_work_item_id category_work_item_id kind_id
                            status_id responsible_id target major_chance_value
                            major_risk_value]

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
        send_data(Order::Report::Csv.new(@report).generate,
                  type: 'text/csv; charset=utf-8; header=present')
      end
    end
  end

  private

  def set_filter_values
    @departments = Department.list
    @clients = WorkItem.joins(:client).list
    @categories = []
    @categories = WorkItem.find(params[:client_work_item_id]).categories.list if params[:client_work_item_id].present?
    @order_kinds = OrderKind.list
    @order_status = OrderStatus.list
    @order_responsibles = Employee.joins(:managed_orders).distinct.list
    @target_scopes = TargetScope.list
  end

  def authorize_class
    authorize!(:reports, Order)
  end
end
