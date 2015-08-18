# encoding: utf-8

class OrderServicesController < ApplicationController

  EMPTY_TICKET = '[leer]'

  include Filterable
  include DryCrud::Rememberable
  include WorktimesReport
  include WorktimesCsv

  self.remember_params = %w(start_date end_date employee_id work_item_id ticket billable)

  before_action :order
  before_action :authorize_class
  before_action :convert_predefined_period, only: [:show]
  before_action :handle_remember_params, only: [:show]
  before_action :set_filter_values, only: [:show]

  def show
    @worktimes = list_worktimes
  end

  def export_worktimes_csv
    set_period
    @worktimes = list_worktimes
    send_worktimes_csv(@worktimes, worktimes_csv_filename)
  end

  def compose_report
    set_report_evaluation
    set_period
  end

  def report
    set_report_evaluation
    set_period
    conditions = {}
    conditions[:worktimes] = { billable: %w(true yes 1).include?(params[:billable].downcase) } if params[:billable].present?
    conditions[:employee_id] = params[:employee_id] if params[:employee_id].present?
    conditions[:ticket] = params[:ticket] if params[:ticket].present?
    render_report(@evaluation, @period, conditions)
  end

  private

  def list_worktimes
    entries = order.worktimes.
                    includes(:employee, :invoice, work_item: :accounting_post).
                    order(:work_date).
                    in_period(@period)

    entries = filter_entries_by_ticket(entries)
    filter_entries_by(entries, :employee_id, :work_item_id, :billable, :invoice_id)
  end

  def filter_entries_by_ticket(entries)
    if params[:ticket] == EMPTY_TICKET
      entries.where(ticket: ['', nil])
    elsif params[:ticket].present?
      entries.where(ticket: params[:ticket])
    else
      entries
    end
  end

  def worktimes_csv_filename
    order_shortnames = order.work_item.path_shortnames
    accounting_post_shortnames = WorkItem.find(params[:work_item_id]).path_shortnames if params[:work_item_id].present?
    employee_shortname = Employee.find(params[:employee_id]).shortname if params[:employee_id].present?
    billable = "billable_#{params[:billable]}" if params[:billable].present?
    ticket = "ticket_#{params[:ticket]}" if params[:ticket].present?
    ['puzzletime', accounting_post_shortnames || order_shortnames, employee_shortname, ticket, billable, '.csv'].compact.join('-')
  end

  def order
    @order ||= Order.find(params[:order_id])
  end

  def set_filter_values
    set_period
    @employees = Employee.where(id: order.worktimes.select(:employee_id)).list
    @tickets = [EMPTY_TICKET] + order.worktimes.order(:ticket).uniq.pluck(:ticket).select(&:present?)
    @accounting_posts = order.work_item.self_and_descendants.leaves.list
  end

  def convert_predefined_period
    if params[:period].present?
      @period = Period.parse(params.delete(:period))
      if @period
        params[:start_date] = I18n.l(@period.start_date)
        params[:end_date] = I18n.l(@period.end_date)
      end
    end
  end

  def set_period
    @period = Period.retrieve(params[:start_date].presence,
                              params[:end_date].presence)
    fail ArgumentError, 'Start Datum nach End Datum' if @period.negative?
  rescue ArgumentError => ex
    # from Period.retrieve or if period.negative?
    flash.now[:alert] = "Ungültige Zeitspanne: #{ex}"
    @period = Period.new(nil, nil)

    params.delete(:start_date)
    params.delete(:end_date)
  end

  def set_report_evaluation
    work_item_id = params[:work_item_id].present? ? params[:work_item_id] : order.work_item_id
    @evaluation = WorkItemEmployeesEval.new(work_item_id)
  end

  def authorize_class
    authorize!(:services, order)
  end

end
