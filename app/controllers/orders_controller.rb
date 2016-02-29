class OrdersController < CrudController
  include Filterable

  self.permitted_attrs = [
    :crm_key, :kind_id, :responsible_id, :department_id, :status_id,
    work_item_attributes: [:name, :shortname, :description, :parent_id],
    order_team_members_attributes: [:id, :employee_id, :comment, :_destroy],
    order_contacts_attributes: [:id, :contact_id_or_crm, :comment, :_destroy]
  ]


  self.remember_params += %w(department_id kind_id status_id responsible_id)

  self.sort_mappings = {
    client: 'work_items.path_names',
    order: 'work_items.name',
    kind: 'order_kinds.name',
    department: 'departments.name',
    responsible: 'employees.lastname || employees.firstname',
    status: 'order_statuses.position' }

  before_action :set_filter_values, only: :index

  after_create :copy_associations

  before_render_form :set_option_values


  ### ACTIONS

  def new
    if params[:copy_id]
      @order = Order::Copier.new(Order.find(params[:copy_id])).copy
    else
      super
    end
  end

  def crm_load
    key = params[:order] && params[:order][:crm_key]
    @crm = Crm.instance
    @order = Order.find_by_crm_key(key)
    @crm_order = @crm.find_order(key)
    if @crm_order
      @client = Client.where(crm_key: @crm_order[:client][:key].to_s).first
    end
  rescue Crm::Error => e
    @crm_error = e.message
  end

  # returns all employees with billable worktimes in given period
  def employees
    from = params[:period_from].presence
    to = params[:period_to].presence
    employees = Employee.with_worktimes_in_period(entry, from, to)
    render json: employees
  end

  private

  def list_entries
    entries = super.includes(:kind, :department, :status, :responsible, :team_members, :targets).
              order('work_items.path_names')
    entries = sort_entries_by_target_scope(entries)

    if (params.keys & %w(department_id kind_id status_id responsible_id)).present?
      filter_entries_by(entries, :department_id, :kind_id, :status_id, :responsible_id)
    else
      default_filter_entries(entries)
    end
  end

  def default_filter_entries(entries)
    entries = remembering_default_filter(entries, :status_id, @order_statuses.first.try(:id))

    if !current_user.management? && current_user.order_responsible?
      remembering_default_filter(entries, :responsible_id, current_user.id)
    elsif current_user.department_id?
      remembering_default_filter(entries, :department_id, current_user.department_id)
    else
      entries
    end
  end

  def remembering_default_filter(entries, attr, value)
    remembered_params[attr.to_s] = params[attr] = value
    entries.where(attr => value)
  end

  def sort_entries_by_target_scope(entries)
    match = params[:sort].to_s.match(/\Atarget_scope_(\d+)\z/)
    if match
      entries.order_by_target_scope(match[1], params[:sort_dir].to_s.downcase == 'desc')
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
      entry.work_item.parent_id ||= (params[:category_active] &&
                                   params[:category_work_item_id].presence) ||
                                  params[:client_work_item_id].presence
    end
  end

  def copy_associations
    return unless params[:copy_id]

    Order::Copier.new(Order.find(params[:copy_id])).copy_associations(entry)
    entry.save
  end

  def index_path
    entry.persisted? && !entry.destroyed? ? edit_order_path(entry) : orders_path(returning: true)
  end

  def set_filter_values
    @departments = Department.list
    @order_kinds = OrderKind.list
    @order_statuses = OrderStatus.list
    @target_scopes = TargetScope.list
  end

  def set_option_values
    if entry.new_record?
      @clients = load_client_options
      @categories = load_category_options
    end

    @contacts = append_crm_contacts(load_contact_options)
    @employees = load_employee_options
  end

  def load_client_options
    clients = Client.list
    if Crm.instance && Crm.instance.restrict_local?
      clients = clients.where(allow_local: true).to_a
      if params[:client_work_item_id].present?
        client = Client.find_by_work_item_id(params[:client_work_item_id])
        clients << client unless clients.include?(client)
      end
    end
    clients
  end

  def load_category_options
    if params[:client_work_item_id].present?
      WorkItem.find(params[:client_work_item_id]).categories.list
    else
      []
    end
  end

  def load_contact_options
    entry.client ? entry.client.contacts.list : []
  end

  def append_crm_contacts(contacts)
    entry.order_contacts.each do |oc|
      if oc.contact.id.nil?
        contacts << oc.contact
      end
    end
    contacts
  end

  def load_employee_options
    Employee.list
  end
end
