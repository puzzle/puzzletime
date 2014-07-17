class OrdersController < ManageController

  self.permitted_attrs = [:kind_id, :responsible_id, :department_id,
                          work_item: [:name, :shortname, :description],
                          employee_ids: []]

  before_render_form :set_clients

  private

  def build_entry
    order = super
    order.build_work_item
    order
  end

  def set_clients
    @clients = Client.list
  end

end