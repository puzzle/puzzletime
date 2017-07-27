#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class OrdersController < CrudController
  include Filterable

  self.permitted_attrs = [
    :crm_key, :kind_id, :responsible_id, :department_id, :status_id,
    work_item_attributes: [:name, :shortname, :description, :parent_id],
    order_team_members_attributes: [:id, :employee_id, :comment, :_destroy],
    order_contacts_attributes: [:id, :contact_id_or_crm, :comment, :_destroy],
    additional_crm_orders_attributes: [:id, :crm_key, :_destroy]
  ]


  self.remember_params += %w(department_id kind_id status_id responsible_id)

  self.sort_mappings = {
    client: 'work_items.path_names',
    order: 'work_items.name',
    kind: 'order_kinds.name',
    department: 'departments.name',
    responsible: 'employees.lastname || employees.firstname',
    status: 'order_statuses.position'
  }

  self.search_columns = %w(work_items.path_shortnames work_items.path_names)

  before_action :set_filter_values, only: :index

  skip_authorization_check only: [:edit]
  skip_authorize_resource only: [:edit]

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

  def edit
    if can?(:write, entry)
      authorize! :edit, entry
      super
    else
      redirect_to order_path(entry)
    end
  end

  def crm_load
    key = params[:order] && params[:order][:crm_key]
    @crm = Crm.instance
    @order = Order.find_by(crm_key: key)
    @crm_order = @crm.find_order(key)
    if @crm_order
      @client = Client.where(crm_key: @crm_order[:client][:key].to_s).first
    end
  rescue Crm::Error => e
    @crm_error = e.message
  end

  # returns all employees with billable worktimes in given period
  def employees
    p = Period.with(params[:period_from].presence, params[:period_to].presence)
    employees = Employee.with_worktimes_in_period(entry, p.start_date, p.end_date)
    render json: employees
  end

  def search
    params[:q] ||= params[:term]
    respond_to do |format|
      format.json do
        @orders = Order.list.where(search_conditions).minimal.limit(20)
      end
    end
  end

  private

  def list_entries
    entries = super.includes(:kind, :department, :status, :responsible,
                             :team_members, :targets, :contacts, :order_uncertainties)
    entries = sort_entries_by_target_scope(entries)
    entries = entries.order('work_items.path_names')

    filter_entries_by(entries, :department_id, :kind_id, :status_id, :responsible_id)
  end

  def handle_remember_params
    if filter_params_present?
      remembered = remembered_params
      store_current_params(remembered)
      clear_void_params(remembered)
    elsif remembered_params?
      restore_params(remembered_params)
    else
      set_default_filter_params
      store_current_params(remembered_params)
    end
  end

  def filter_params_present?
    (params.keys & %w(department_id kind_id status_id responsible_id)).present?
  end

  def set_default_filter_params
    params[:status_id] = OrderStatus.defaults.pluck(:id)
    if !current_user.management? && current_user.order_responsible?
      params[:responsible_id] = current_user.id
    elsif current_user.department_id?
      params[:department_id] = current_user.department_id
    end
  end

  def sort_entries_by_target_scope(entries)
    match = params[:sort].to_s.match(/\Atarget_scope_(\d+)\z/)
    if match
      entries.order_by_target_scope(match[1], params[:sort_dir].to_s.casecmp('desc').zero?)
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
    @responsibles = load_responsibles
    @order_kinds = OrderKind.list
    @order_statuses = OrderStatus.list
    @target_scopes = TargetScope.list
  end

  def load_responsibles
    Employee
      .joins(:managed_orders)
      .employed_ones(Period.current_year)
      .select('employees.*, ' \
              "CASE WHEN employees.id = #{current_user.id.to_s(:db)} THEN 1 " \
              'ELSE 2 END AS employee_order') # current user should be on top
      .reorder('employee_order, lastname, firstname')
  end

  def set_option_values
    if entry.new_record?
      @clients = load_client_options
      @categories = load_category_options
    end

    @contacts = append_crm_contacts(load_contact_options.to_a)
    @employees = load_employee_options
  end

  def load_client_options
    clients = Client.list
    if Crm.instance && Crm.instance.restrict_local?
      clients = clients.where(allow_local: true).to_a
      if params[:client_work_item_id].present?
        client = Client.find_by(work_item_id: params[:client_work_item_id])
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
      if oc.contact && oc.contact.id.nil?
        contacts << oc.contact
      end
    end
    contacts
  end

  def load_employee_options
    Employee.list
  end

  # No search box even with search columns defined (only used for search action).
  def search_support?
    false
  end

end
