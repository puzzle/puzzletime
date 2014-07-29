class OrdersController < ManageController

  self.permitted_attrs = [:crm_key, :kind_id, :responsible_id, :department_id, :status_id,
                          work_item_attributes: [:name, :shortname, :description],
                          employee_ids: []]

  self.sort_mappings = {
    client: 'work_items.path_names',
    order: 'work_items.name',
    kind: 'order_kinds.name',
    department: 'departments.name',
    responsible: 'employees.lastname || employees.firstname',
    status: 'order_statuses.position' }

  # TODO: authorization (Die Erstellung von Aufträgen soll durch die Rolle AV und Managment möglich sein.)

  before_render_index :set_target_scopes
  before_render_form :set_clients

  private

  def list_entries
    super.includes(:kind, :department, :status, :responsible, :targets, :employees).
          order('work_items.path_names')
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

  def set_target_scopes
    @target_scopes = TargetScope.list
  end

end