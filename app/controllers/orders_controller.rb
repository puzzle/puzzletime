class OrdersController < ManageController

  self.permitted_attrs = [:kind_id, :responsible_id, :department_id, :status_id,
                          work_item_attributes: [:name, :shortname, :description],
                          employee_ids: []]

  # TODO: authorization (Die Erstellung von Aufträgen soll durch die Rolle AV und Managment möglich sein.)

  before_render_form :set_clients

  private

  def build_entry
    order = super
    order.build_work_item
    order.department_id ||= current_user.department_id
    order.responsible_id ||= current_user.id
    order
  end

  def assign_attributes
    super
    entry.work_item.parent_id = (params[:category_active] &&
                                 params[:category_work_item_id].presence) ||
                                params[:client_work_item_id].presence
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

end