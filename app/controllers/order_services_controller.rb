# encoding: utf-8

class OrderServicesController < ApplicationController
  EMPTY = '[leer]'
  EMPTY_TICKET = EMPTY
  EMPTY_INVOICE = OpenStruct.new(id: EMPTY, reference: EMPTY)

  include Filterable
  include DryCrud::Rememberable
  include WorktimesReport
  include WorktimesCsv

  self.remember_params = %w(start_date end_date employee_id work_item_id ticket billable invoice_id)

  before_action :order
  before_action :authorize_class

  def show
    convert_predefined_period
    handle_remember_params
    set_filter_values
    @worktimes = list_worktimes(@period).includes(:invoice, work_item: :accounting_post)
  end

  def export_worktimes_csv
    set_period
    @worktimes = list_worktimes(@period).includes(:work_item)
    send_worktimes_csv(@worktimes, worktimes_csv_filename)
  end

  def compose_report
    prepare_report_header
  end

  def report
    period = prepare_report_header
    render_report(list_worktimes(period))
  end

  private

  def list_worktimes(period)
    entries = order.worktimes.
              includes(:employee, :work_item).
              order(:work_date).
              in_period(period)
    entries = filter_entries_allow_empty_by(entries, EMPTY, :ticket, :invoice_id)
    filter_entries_by(entries, :employee_id, :work_item_id, :billable)
  end

  def worktimes_csv_filename
    order_shortnames = order.work_item.path_shortnames
    if params[:work_item_id].present?
      accounting_post_shortnames = WorkItem.find(params[:work_item_id]).path_shortnames
    end
    if params[:employee_id].present?
      employee_shortname = Employee.find(params[:employee_id]).shortname
    end
    billable = "billable_#{params[:billable]}" if params[:billable].present?
    ticket = "ticket_#{params[:ticket]}" if params[:ticket].present?
    ['puzzletime',
     accounting_post_shortnames || order_shortnames,
     employee_shortname,
     ticket,
     billable,
     '.csv'].compact.join('-')
  end

  def order
    @order ||= Order.find(params[:order_id])
  end

  def set_filter_values
    set_period
    @employees = Employee.where(id: order.worktimes.select(:employee_id)).list
    @tickets = [EMPTY_TICKET] + order.worktimes.order(:ticket).uniq.pluck(:ticket).select(&:present?)
    @accounting_posts = order.work_item.self_and_descendants.leaves.list
    @invoices = [EMPTY_INVOICE] + order.invoices
  end

  def convert_predefined_period
    return if params[:period].blank?

    @period = Period.parse(params.delete(:period))
    if @period
      params[:start_date] = I18n.l(@period.start_date)
      params[:end_date] = I18n.l(@period.end_date)
    end
  end

  def prepare_report_header
    @work_item = WorkItem.find(params[:work_item_id].present? ? params[:work_item_id] : order.work_item_id)
    @employee = Employee.find(params[:employee_id]) if params[:employee_id].present?
    set_period_with_invoice
  end

  def set_period_with_invoice
    if params[:invoice_id].present? && params[:invoice_id] != EMPTY &&
      params[:start_date].blank? && params[:end_date].blank?
      invoice = Invoice.find(params[:invoice_id])
      @period = Period.retrieve(invoice.period_from, invoice.period_to)
      # return an open period to get all worktimes for the given invoice_id,
      # even if they are not in the defined invoice period.
      # (@period is only used to display from and to dates)
      Period.new(nil, nil)
    else
      set_period
    end
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
    authorize!(:services, order)
  end

end
