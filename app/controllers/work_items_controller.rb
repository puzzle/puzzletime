class WorkItemsController < ManageController
  self.permitted_attrs = :name, :shortname, :description

  def new
    super do |format|
      format.js { render partial: 'form' }
    end
  end
end