class SectorsController < ManageController
  self.permitted_attrs = [:name, :active]
end
