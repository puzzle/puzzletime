class WorkItemsController < ManageController
  self.permitted_attrs = :name, :shortname, :description

end