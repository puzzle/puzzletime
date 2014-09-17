class OrdersController < ManageController

  self.permitted_attrs = [:crm_key, :kind_id, :responsible_id, :department_id, :status_id,
                          work_item_attributes: [:name, :shortname, :description],
                          employee_ids: []]

  self.remember_params += %w(department_id kind_id status_id)

  self.sort_mappings = {
    client: 'work_items.path_names',
    order: 'work_items.name',
    kind: 'order_kinds.name',
    department: 'departments.name',
    responsible: 'employees.lastname || employees.firstname',
    status: 'order_statuses.position' }

  before_action :set_filter_values, only: :index
  before_render_form :set_clients

  def crm_load
    key = params[:order][:crm_key]
    @crm = Crm.instance
    @order = Order.where(crm_key: key).first
    @crm_order = @crm.find_order(key)
    if @crm_order
      @client = Client.where(crm_key: @crm_order[:client][:key].to_s).first
    end
  end

  def cockpit
    render action: 'cockpit'
  end

  private

  def list_entries
    entries = super.includes(:kind, :department, :status, :responsible, :targets, :employees).
                    order('work_items.path_names')
    entries = sort_entries_by_target_scope(entries)

    if (params.keys & %w(department_id kind_id status_id)).present?
      filter_entries_by(entries, :department_id, :kind_id, :status_id)
    else
      default_filter_entries(entries)
    end
  end

  def filter_entries_by(entries, *keys)
    keys.inject(entries) do |filtered, key|
      if params[key].present?
        filtered.where(key => params[key])
      else
        filtered
      end
    end
  end

  def default_filter_entries(entries)
    params[:status_id] = @order_statuses.first.id
    entries = entries.where(status_id: params[:status_id])

    if !current_user.management? && current_user.order_responsible?
      entries.where(responsible_id: current_user.id)
    elsif current_user.department_id?
      params[:department_id] = current_user.department_id
      entries.where(department_id: current_user.department_id)
    else
      entries
    end
  end

  def sort_entries_by_target_scope(entries)
    match = params[:sort].to_s.match(/\Atarget_scope_(\d+)\z/)
    if match
      entries.
        joins('LEFT JOIN order_targets sort_target ' \
              'ON sort_target.order_id = orders.id ').
        where('sort_target.target_scope_id = ? OR sort_target.id IS NULL', match[1]).
        reorder('sort_target.rating')
    else
      entries
    end
  end

  def build_entry
    order = super
    order.build_work_item
    order.department_id ||= current_user.department_id
    order.responsible_id ||= current_user.id
    order
  end

  def assign_attributes
    super
    if entry.new_record?
      entry.work_item.parent_id = (params[:category_active] &&
                                   params[:category_work_item_id].presence) ||
                                  params[:client_work_item_id].presence
    end
  end

  def set_clients
    @clients = Client.list
    @employees = Employee.list # TODO: restrict only with employment?
    if params[:client_work_item_id].present?
      @categories = WorkItem.find(params[:client_work_item_id]).categories.list
    else
      @categories = []
    end
  end

  def set_filter_values
    @departments = Department.list
    @order_kinds = OrderKind.list
    @order_statuses = OrderStatus.list
    @target_scopes = TargetScope.list
  end

end
