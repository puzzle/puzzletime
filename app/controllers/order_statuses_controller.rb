class OrderStatusesController < ManageController

  self.permitted_attrs = [:name, :style, :position]

end