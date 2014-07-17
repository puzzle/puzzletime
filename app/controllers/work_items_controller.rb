class WorkItemsController < ManageController

  self.permitted_attrs = :name, :shortname, :description, :parent_id

end