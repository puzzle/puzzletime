class PathItemsController < ManageController
  self.permitted_attrs = :name, :shortname

  def new
    super do |format|
      format.js { render partial: 'form' }
    end
  end
end