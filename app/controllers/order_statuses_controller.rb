class OrderStatusesController < ManageController

  self.permitted_attrs = [:name, :position]

end