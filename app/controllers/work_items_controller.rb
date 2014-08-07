class WorkItemsController < ManageController

  self.permitted_attrs = :name, :shortname, :description, :parent_id
  self.search_columns = [:path_shortnames, :path_names, :description]
  
  def search
    params[:q] ||= params[:term]
    respond_to do |format|
      format.json do
        @work_items = WorkItem.list.
                            where(leaf: true).
                            where(search_conditions).
                            select(:id, :name, :path_shortnames, :description).
                            limit(20)
      end
    end
  end

end