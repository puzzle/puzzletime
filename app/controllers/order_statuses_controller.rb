class OrderStatusesController < ManageController
  self.permitted_attrs = [:name, :style, :closed, :position, :default]
end
