# encoding: utf-8
class AccountingPostsController < CrudController

  self.permitted_attrs = [:closed, :offered_hours, :offered_rate, :discount_percent, :discount_fixed,
                          :portfolio_item_id, :reference, :billable, :description_required, :ticket_required,
                          work_item_attributes: [:name, :shortname, :description]]

  before_action :set_order
  before_update :remember_old_work_item_id
  after_update :move_work_times

  helper_method :order

  def create
    create_update(:create)
  end

  def update
    create_update(:update)
  end

  def destroy
    super(location: cockpit_order_path(id: order.id, returning: true))
  end

  private

  attr_reader :order, :old_work_item_id

  def create_update(action)
    assign_attributes
    options = {}
    if book_on_order_requested? && !book_on_order_allowed?
      flash[:alert] = "'Direkt auf Auftrag buchen' gewählt, aber es existieren bereits (andere) Buchungspositionen"
      options[:success] = false
      options[:location] = new_accounting_post_path(order_id: order.id)
    else
      options[:success] = with_callbacks(action.to_sym, :save) { entry.save }
      options[:location] = cockpit_order_path(id: order.id, returning: true)
    end
    respond_with(entry, options)
  end

  def build_entry
    accounting_post = super
    accounting_post.build_work_item
    accounting_post
  end

  def book_on_order_requested?
    params['book_on_order'] == 'true'
  end

  def book_on_order_allowed?
    order.accounting_posts.count == 0 || order.accounting_posts.to_a == [entry]
  end

  def book_on_order?
    book_on_order_requested? && book_on_order_allowed?
  end

  def book_on_order_change?
    book_on_order? ^ (entry.work_item_id == order.work_item_id)
  end

  def assign_attributes
    if entry.new_record?
      entry.work_item = book_on_order? ? order.work_item : WorkItem.new(work_item_attributes)
    else
      if book_on_order_change?
        if book_on_order?
          entry.work_item = order.work_item
        else
          entry.work_item = WorkItem.new(work_item_attributes)
        end
      else
        entry.attributes = model_params.slice(:work_item_attributes) unless book_on_order?
      end
    end
    entry.attributes = model_params.except(:work_item_attributes)
  end

  def work_item_attributes
    parent_id = book_on_order? ? order.work_item.parent_id : order.work_item_id
    (model_params[:work_item_attributes] || {}).merge(parent_id: parent_id)
  end

  def set_order
    @order = entry.new_record? ? Order.find(params.require(:order_id)) : entry.order
  end

  def remember_old_work_item_id
    @old_work_item_id = entry.work_item_id_was
  end

  def move_work_times
    if entry.work_item_id != old_work_item_id
      Worktime.where(work_item_id: old_work_item_id).update_all(work_item_id: entry.work_item_id)
      WorkItem.find(old_work_item_id).destroy unless old_work_item_id == order.work_item_id
    end
  end


end