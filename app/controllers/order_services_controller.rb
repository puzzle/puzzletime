# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class OrderServicesController < ApplicationController
  EMPTY = '[leer]'
  EMPTY_TICKET = EMPTY
  EMPTY_INVOICE = OpenStruct.new(id: EMPTY, reference: EMPTY)
  MAX_ENTRIES = 250

  include Filterable
  include WithPeriod
  include DryCrud::Rememberable
  include WorktimesReport
  include WorktimesCsv

  self.remember_params = %w[start_date end_date period_shortcut employee_id work_item_ids ticket
                            billable invoice_id]

  before_action :order
  before_action :authorize_class

  def show
    handle_remember_params
    set_filter_values
    @worktimes =
      list_worktimes(@period)
      .includes(:invoice, work_item: :accounting_post)
      .limit(MAX_ENTRIES)
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
    entries = order.worktimes
                   .includes(:employee, :work_item)
                   .order(:work_date)
                   .in_period(period)
    entries = filter_entries_allow_empty_by(entries, EMPTY, :ticket, :invoice_id)
    filter_entries_allow_custom_mappings_by(entries, { work_item_ids: :work_item_id }, :employee_id, :billable, :meal_compensation)
  end

  def worktimes_csv_filename
    Order::Services::CsvFilenameGenerator.new(order, params).filename
  end

  def order
    @order ||= Order.find(params[:order_id])
  end

  def set_filter_values
    set_period
    set_filter_employees
    set_filter_tickets
    set_filter_accounting_posts
    set_filter_invoices
  end

  def prepare_report_header
    params[:work_item_ids] ||= [params[:work_item_id].presence || order.work_item_id]
    @work_items = WorkItem.find(params[:work_item_ids])
    @employee = Employee.find(params[:employee_id]) if params[:employee_id].present?
    set_period_with_invoice
  end

  def set_period_with_invoice
    if params[:invoice_id].present? && params[:invoice_id] != EMPTY &&
       params[:start_date].blank? && params[:end_date].blank?
      invoice = Invoice.find(params[:invoice_id])
      @period = Period.new(invoice.period_from, invoice.period_to)
      # return an open period to get all worktimes for the given invoice_id,
      # even if they are not in the defined invoice period.
      # (@period is only used to display from and to dates)
      Period.new(nil, nil)
    else
      set_period
    end
  end

  def set_filter_employees
    ids = order.worktimes.in_period(@period).select(:employee_id).distinct
    @employees = Employee.where(id: ids).list
  end

  def set_filter_tickets
    @tickets = [EMPTY_TICKET] +
               order.worktimes.in_period(@period)
                    .order(:ticket)
                    .distinct
                    .pluck(:ticket)
                    .select(&:present?)
  end

  def set_filter_accounting_posts
    ids = order.worktimes.in_period(@period).select(:work_item_id).distinct
    @accounting_posts = WorkItem.where(id: ids).list
  end

  def set_filter_invoices
    @invoices = [EMPTY_INVOICE] + order.invoices.list
  end

  def authorize_class
    authorize!(:services, order)
  end
end
