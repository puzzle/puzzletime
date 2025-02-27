# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class InvoicesController < CrudController
  self.nesting = [Order]

  self.permitted_attrs = [:billing_date, :due_date, :period_from, :period_to, :period_shortcut,
                          :billing_address_id, :grouping, { employee_ids: [], work_item_ids: [] }]

  self.sort_mappings = { period: :period_from, manual?: :grouping }

  helper_method :checked_work_item_ids, :checked_employee_ids, :order

  prepend_before_action :entry, only: %i[show new create edit update destroy sync]

  before_render_index :load_totals_paid
  before_render_form :load_associations

  include WithPeriod

  def show
    respond_to do |format|
      format.html
      format.json
      format.pdf do
        raise ActionController::UnknownFormat unless Invoicing.instance

        pdf = Invoicing.instance.get_pdf(entry)
        send_data(pdf,
                  filename: "#{entry.reference}.pdf",
                  type: 'application/pdf',
                  disposition: :inline)
      end
    end
  end

  def new
    assign_attributes
    @autoselect_workitems_and_employees = true
  end

  def sync
    if Invoicing.instance
      begin
        Invoicing.instance.sync_invoice(entry)
        flash[:notice] = "Die Rechnung #{entry} wurde aktualisiert."
      rescue Invoicing::Error => e
        flash[:error] = "Fehler im Invoicing Service: #{e.message}"
      end
    end
    redirect_to index_path
  end

  def destroy(options = {})
    destroyed = attempt_destroy_record

    respond_to do |format|
      if destroyed
        format.html { redirect_on_success(options) }
        format.json { head :no_content }
      else
        format.html { redirect_on_failure(options) }
        format.json { render json: entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # AJAX
  def preview_total
    assign_attributes
  end

  # AJAX
  def billing_addresses
    client_id = params[model_identifier][:billing_client_id].presence
    @billing_client = client_id && Client.find(client_id)
    @billing_addresses = client_id ? load_billing_addresses(@billing_client) : []
    @billing_address_id = @billing_addresses.first.id if @billing_addresses.size == 1
  end

  # AJAX
  def filter_fields
    from = model_params[:period_from]
    to = model_params[:period_to]
    @employees = employees_for_period(from, to)
    @work_items = work_items_for_period(from, to)
    # replace employees_ids in entry with the list of actually selectable employees 
    entry.employee_ids = @employees.pluck(:id) 
    entry.work_item_ids = @work_items.pluck(:id)
  end

  private

  def find_entry
    super
  rescue ActiveRecord::RecordNotFound
    # happens when changing order in top dropdown while editing invoice.
    redirect_to order_invoices_path(order)
    Invoice.new
  end

  def model_params
    model_params = params[model_identifier] || ActionController::Parameters.new
    model_params.permit(permitted_attrs).tap do |attrs|
      # map attributes from order_services filter form
      copy_attrs_from_params(attrs)
      init_default_attrs(attrs)
    end
  end

  def copy_attrs_from_params(attrs)
    if params[:period_shortcut].present?
      period = build_period
      attrs[:period_from] ||= period.start_date
      attrs[:period_to] ||= period.end_date
    else
      attrs[:period_from] ||= params[:start_date]
      attrs[:period_to] ||= params[:end_date]
    end
    set_period # sets @period based on params[:period_shortcut] if set, else based on params[:start_date] and params[:end_date]
    attrs[:grouping] = 'manual' if params[:manual_invoice]
    attrs[:employee_ids] = Array(attrs[:employee_ids]) << params[:employee_id] if params[:employee_id].present?
    return if params[:work_item_id].blank?

    attrs[:work_item_ids] = Array(attrs[:work_item_ids]) << params[:work_item_id]
  end

  def init_default_attrs(attrs)
    attrs[:billing_date] ||= l(billing_date)
    attrs[:due_date] ||= l(due_date) if due_date.present?
    attrs[:billing_address_id] ||= default_billing_address_id
    attrs[:grouping] ||= last_grouping
    if attrs[:employee_ids].blank?
      attrs[:employee_ids] = employees_for_period(attrs[:period_from],
                                                  attrs[:period_to]).map(&:id)
    end
    return if attrs[:work_item_ids].present?

    attrs[:work_item_ids] = work_items_for_period(attrs[:period_from],
                                                  attrs[:period_to]).map(&:id)
  end

  def order
    parent
  end

  def load_totals_paid
    paid = order.invoices.where(status: 'paid')
    @total_amount = order.invoices.sum(:total_amount)
    @total_amount_paid = paid.sum(:total_amount)
    @total_amount_open = @total_amount - @total_amount_paid

    @total_hours       = order.invoices.sum(:total_hours)
    @total_hours_paid  = paid.sum(:total_hours)
    @total_hours_open  = @total_hours - @total_hours_paid
  end

  def load_associations
    @employees = employees_for_period(entry.period_from, entry.period_to)
    @work_items = work_items_for_period(entry.period_from, entry.period_to)
    @billing_clients = Client.list
    @billing_client = entry.billing_client
    @billing_addresses = load_billing_addresses(@billing_client)
    @billing_address_id = entry.billing_address_id || entry.order.default_billing_address_id
  end

  def employees_for_period(from, to)
    p = Period.with(from, to)
    Employee.with_worktimes_in_period(order, p.start_date, p.end_date)
  end

  def work_items_for_period(from, to)
    p = Period.with(from, to)
    WorkItem.with_worktimes_in_period(order, p.start_date, p.end_date)
  end

  # determine the checked work_items in the form
  def checked_work_item_ids
      entry.work_item_ids.presence
  end

  # determine the checked employee_ids in the form
  def checked_employee_ids
    entry.employee_ids.presence
  end

  def billing_clients
    Client.list
  end

  def load_billing_addresses(client)
    client.billing_addresses.includes(:contact).list
  end

  def default_billing_address_id
    order.default_billing_address_id
  end

  def payment_period
    order.contract.try(:payment_period)
  end

  def billing_date
    entry.billing_date || Time.zone.today
  end

  def due_date
    entry.due_date || (billing_date + payment_period.days) if payment_period.present?
  end

  def last_grouping
    order.invoices.list.first.try(:grouping)
  end

  def autoselect_all?
    @autoselect_workitems_and_employees
  end

  def attempt_destroy_record
    run_callbacks(:destroy) do
      if entry.destroyable?
        entry.destroy
      else
        Invoice.transaction do
          entry.status = entry.status == 'sent' ? 'cancelled' : 'deleted'
          entry.ordertimes.each do |ordertime|
            ordertime.invoice_id = nil
            ordertime.save
          end
          entry.save
        end
      end
    end
  end
end
