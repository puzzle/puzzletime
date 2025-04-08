# frozen_string_literal: true

class InvoiceReportsController < ApplicationController
  include DryCrud::Rememberable
  include WithPeriod

  before_action :authorize_class

  def index
    set_period
    @report = Invoice::Report.new(@period, params)
    set_filter_values
  end

  private

  def set_filter_values
    @departments = Department.list
    @clients = WorkItem.joins(:client).list
    @order_kinds = OrderKind.list
    @invoice_status = Invoice::STATUSES.map { |v| IdValue.new(v, I18n.t("activerecord.attributes.invoice/statuses.#{v}")) }
    @order_responsibles = Employee.joins(:managed_orders).distinct.list
  end

  def authorize_class
    authorize!(:reports, Invoice)
  end
end
