# encoding: utf-8
class InvoicesController < CrudController

  self.nesting = [Order]

  self.permitted_attrs = [:due_date, :period_from, :period_to, :add_vat, :billing_address_id, :grouping,
                          employee_ids: [], work_item_ids: []]

  helper_method :all_work_items, :checked_work_item_ids, :all_employees, :checked_employee_ids,
                :order, :billing_addresses

  before_action :order

  def new
    assign_attributes
  end

  def preview_total
    assign_attributes
    render layout: false
  end

  def pdf
    pdf = Invoicing.instance.get_pdf(entry)
    send_data(pdf, filename: "#{entry.reference}.pdf", type: 'application/pdf', disposition: :inline)
  end

  private

  def model_params
    p = (params[model_identifier] || ActionController::Parameters.new).permit(permitted_attrs).tap do |attrs|
      # map attributes from oder_services filter form
      attrs[:period_from] ||= params[:start_date]
      attrs[:period_to] ||= params[:end_date]
      attrs[:grouping] = 'manual' if params[:manual_invoice]
      attrs[:employee_ids] = Array(attrs[:employee_ids]) << params[:employee_id] if params[:employee_id].present?
      attrs[:work_item_ids] = Array(attrs[:work_item_ids]) << params[:work_item_id] if params[:work_item_id].present?

      # defaults
      attrs[:billing_date] ||= l(billing_date)
      attrs[:due_date] ||= l(due_date) if due_date.present?
      attrs[:billing_address_id] ||= default_billing_address_id
      attrs[:employee_ids] = all_employee_ids if attrs[:employee_ids].blank?
      attrs[:work_item_ids] = all_work_item_ids if attrs[:work_item_ids].blank?
    end
  end

  def order
    @order ||= Order.find(params[:order_id])
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

  def billing_addresses
    order.client.billing_addresses
  end

  def default_billing_address_id
    order.default_billing_address_id
  end

  def payment_period
    order.contract.try(:payment_period)
  end

  def billing_date
    entry.billing_date || Date.today
  end

  def due_date
    entry.due_date || billing_date + payment_period.days if payment_period.present?
  end
end
