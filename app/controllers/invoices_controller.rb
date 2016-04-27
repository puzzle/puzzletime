# encoding: utf-8

class InvoicesController < CrudController

  self.nesting = [Order]

  self.permitted_attrs = [:due_date, :period_from, :period_to, :add_vat, :billing_address_id,
                          :grouping, employee_ids: [], work_item_ids: []]

  helper_method :checked_work_item_ids, :checked_employee_ids, :order

  before_render_form :load_associations

  def show
    respond_to do |format|
      format.html
      format.json
      format.pdf do
        if Invoicing.instance
          pdf = Invoicing.instance.get_pdf(entry)
          send_data(pdf,
                    filename: "#{entry.reference}.pdf",
                    type: 'application/pdf',
                    disposition: :inline)
        else
          fail ActionController::UnknownFormat
        end
      end
    end
  end

  def new
    assign_attributes
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
  def period_employees
    from = model_params[:period_from]
    to = model_params[:period_to]
    @employees = Employee.with_worktimes_in_period(order, from, to)
  end

  private

  def find_entry
    super
  rescue ActiveRecord::RecordNotFound => e
    # happens when changing order in top dropdown while editing invoice.
    redirect_to order_invoices_path(order)
    Invoice.new
  end

  def model_params
    (params[model_identifier] || ActionController::Parameters.new).
      permit(permitted_attrs).tap do |attrs|
      # map attributes from oder_services filter form
      attrs[:period_from] ||= params[:start_date]
      attrs[:period_to] ||= params[:end_date]
      attrs[:grouping] = 'manual' if params[:manual_invoice]
      if params[:employee_id].present?
        attrs[:employee_ids] = Array(attrs[:employee_ids]) << params[:employee_id]
      end
      if params[:work_item_id].present?
        attrs[:work_item_ids] = Array(attrs[:work_item_ids]) << params[:work_item_id]
      end

      # defaults
      attrs[:billing_date] ||= l(billing_date)
      attrs[:due_date] ||= l(due_date) if due_date.present?
      attrs[:billing_address_id] ||= default_billing_address_id
      attrs[:employee_ids] = all_employee_ids if attrs[:employee_ids].blank?
      attrs[:work_item_ids] = all_work_item_ids if attrs[:work_item_ids].blank?
    end
  end

  def order
    parent
  end

  def load_associations
    @employees = all_employees
    @work_items = all_work_items
    @billing_clients = Client.list
    @billing_client = entry.billing_client
    @billing_addresses = load_billing_addresses(@billing_client)
    @billing_address_id = entry.billing_address_id || entry.order.default_billing_address_id
  end

  def all_work_items
    order.accounting_posts.map(&:work_item)
  end

  def all_work_item_ids
    all_work_items.map(&:id)
  end

  def checked_work_item_ids
    entry.work_item_ids.presence || all_work_items.map(&:id)
  end

  def all_employees
    Employee.where(id: order.worktimes.billable.select(:employee_id).uniq).list
  end

  def all_employee_ids
    all_employees.map(&:id)
  end

  def checked_employee_ids
    entry.employee_ids.presence || all_employees.pluck(:id)
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
    entry.due_date || billing_date + payment_period.days if payment_period.present?
  end
end
