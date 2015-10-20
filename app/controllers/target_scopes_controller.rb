class TargetScopesController < ManageController
  self.permitted_attrs = [:name, :icon, :position]
end
