# frozen_string_literal: true

class InvoiceReportsController < ApplicationController
  include DryCrud::Rememberable
  include WithPeriod

  self.remember_params = %w[start_date end_date period_shortcut department_id
                            client_work_item_id kind_id status responsible_id ]

  before_action :authorize_class

  def index
    respond_to do |format|
      set_period
      @report = Invoice::Report.new(@period, params)
      format.html do
        set_filter_values
        unless @report.filters_defined?
          set_default_params
          set_period
          @report = Invoice::Report.new(@period, params)
        end
      end
      format.js do
        set_filter_values
      end
      format.csv do
        send_data(Invoice::Report::Csv.new(@report).generate,
                  type: 'text/csv; charset=utf-8; header=present')
      end
    end
  end

  def sync
    if params['invoice_id'].blank?
      flash[:error] = 'Interner Puzzletime Fehler beim Sync der Rechnung' # rubocop:disable Rails/I18nLocaleTexts
      redirect_to reports_invoices_path(params.to_unsafe_h)
      return
    end

    invoice = Invoice.find(params[:invoice_id])

    if Invoicing.instance
      begin
        Invoicing.instance.sync_invoice(invoice)
        flash[:notice] = "Die Rechnung #{invoice} wurde aktualisiert."
      rescue Invoicing::Error => e
        flash[:error] = "Fehler im Invoicing Service: #{e.message}"
      end
    end
    redirect_to reports_invoices_path(params.to_unsafe_h)
  end

  private

  def set_filter_values
    @departments = Department.list
    @clients = WorkItem.joins(:client).list
    @order_kinds = OrderKind.list
    @invoice_status = Invoice::STATUSES.map { |v| IdValue.new(v, I18n.t("activerecord.attributes.invoice/statuses.#{v}")) }
    @order_responsibles = Employee.joins(:managed_orders).distinct.list
  end

  def set_default_params
    return if @report.filters_defined?

    responsible_id = @user.id if Employee.joins(:managed_orders).exists?(id: @user.id)

    params.reverse_merge!(department_id: @user.department_id, responsible_id: responsible_id, period_shortcut: '0q')
  end

  def authorize_class
    authorize!(:reports, Invoice)
  end
end
