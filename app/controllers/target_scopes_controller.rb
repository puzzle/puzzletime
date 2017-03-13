class TargetScopesController < ManageController
  self.permitted_attrs = [:name, :icon, :position,
                          :rating_green_description, :rating_orange_description, :rating_red_description]
end
