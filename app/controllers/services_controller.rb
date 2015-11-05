class ServicesController < ManageController
  self.permitted_attrs = [:name, :active]
end
