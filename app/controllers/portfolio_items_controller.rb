class PortfolioItemsController < ManageController
  self.permitted_attrs = [:name, :active]
end
