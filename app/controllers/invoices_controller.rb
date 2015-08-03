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
    app/controllers/invoices_controller.rb
    @total = entry.calculate_total_amount
    render layout: false
  end

  private

  def model_params
    (params[model_identifier] || ActionController::Parameters.new).permit(permitted_attrs).tap do |attrs|
      # defaults
      attrs[:billing_date] ||= Date.today
      attrs[:due_date] ||= calculate_due_date(attrs[:billing_date])
      attrs[:billing_address] ||= default_billing_address

      # map attributes from oder_services filter form
      attrs[:period_from] ||= params[:start_date]
      attrs[:period_to] ||= params[:end_date]
      attrs[:grouping] = 'manual' if params[:manual_invoice]
      attrs[:employee_ids] = Array(attrs[:employee_ids]) << params[:employee_id] if params[:employee_id]
      attrs[:work_item_ids] = Array(attrs[:work_item_ids]) << params[:work_item_id] if params[:work_item_id]
    end
  end

  def index_path
    order_accounting_posts_path(entry.order)
  end

  def order
    @order ||= Order.find(params[:order_id])
  end

  def all_work_items
    order.accounting_posts.list.map(&:work_item)
  end

  def checked_work_item_ids
    entry.work_item_ids.presence || all_work_items.map(&:id)
  end

  def all_employees
    Employee.where(id: order.worktimes.select(:employee_id)).list
  end

  def checked_employee_ids
    entry.employee_ids.presence || all_employees.pluck(:id)
  end

  def billing_addresses
    order.client.billing_addresses
  end

  def default_billing_address
    order.client.default_billing_address
  end

  def payment_period
    order.contract.try(:payment_period)
  end

  def calculate_due_date(billing_date)
    billing_date + payment_period.days if payment_period.present?
  end
end
