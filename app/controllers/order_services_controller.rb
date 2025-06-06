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
    Rails.logger.debug '-'*80
    Rails.logger.debug 'Start Report'
    Rails.logger.debug '-'*80

    Rails.logger.debug 'Setting period'
    period = prepare_report_header
    Rails.logger.debug "period: #{period.inspect}"

    Rails.logger.debug 'Preparing Worktimes'
    prepare_worktimes(list_worktimes(period))

    Rails.logger.debug 'Check prepared data'
    Rails.logger.debug "@order:       #{@order.inspect}"
    Rails.logger.debug "@worktimes:   #{@worktimes.inspect}"
    Rails.logger.debug "@tickets:     #{@tickets.inspect}"
    Rails.logger.debug "@ticket_view: #{@ticket_view.inspect}"
    Rails.logger.debug "@employees:   #{@employees.inspect}"
    Rails.logger.debug "@employee:    #{@employee.inspect}"
    Rails.logger.debug "@work_items:  #{@work_items.inspect}"
    Rails.logger.debug "@period:      #{@period.inspect}"

    Rails.logger.debug 'Setting time_report_data'
    time_rapport_data = Order::Services::TimeRapportData.new(
      order: @order,
      worktimes: @worktimes,
      tickets: @tickets,
      ticket_view: @ticket_view,
      employees: @employees,
      employee: @employee,
      work_items: @work_items,
      period: @period
    )

    Rails.logger.debug 'Check params'
    Rails.logger.debug "params: #{params.inspect}"

    Rails.logger.debug 'Setting pdf_generator'
    pdf_generator = Order::Services::TimeRapportPdfGenerator.new(time_rapport_data, params)
    Rails.logger.debug "pdf_generator: #{pdf_generator.inspect}"

    Rails.logger.debug 'Preparing data to send'
    data = pdf_generator.generate_pdf.render
    filename = "zeitrapport-#{@work_items[0].top_item.client.shortname}-#{@order.shortname}-#{@period.to_s.parameterize}.pdf"
    Rails.logger.debug "data:     #{data}"
    Rails.logger.debug "filename: #{filename}"

    Rails.logger.debug 'Sending data'
    send_data data, filename: filename, type: 'application/pdf', disposition: 'inline'
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
    work_item_ids = params[:work_item_ids].presence
    work_item_ids ||= params[:work_item_id].presence
    work_item_ids ||= order.accounting_posts.collect(&:work_item_id)
    work_item_ids = Array.wrap(work_item_ids)
    @work_items = WorkItem.find(work_item_ids)
    @order = order
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
                    .compact_blank
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
