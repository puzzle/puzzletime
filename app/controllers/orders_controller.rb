class OrdersController < ManageController

  self.permitted_attrs = [:kind_id, :responsible_id, :department_id,
                          path_item: [:name, :shortname],
                          employee_ids: []]

  before_render_form :set_clients

  private

  def build_entry
    order = super
    order.build_path_item
    order
  end

  def set_clients
    @clients = Client.list
  end

end