class WorkItemsController < ManageController
  self.permitted_attrs = :name, :shortname, :description, :parent_id
  self.search_columns = [:path_shortnames, :path_names, :description]

  def search
    params[:q] ||= params[:term]
    respond_to do |format|
      format.json do
        @work_items = WorkItem.recordable.
                      list.
                      where(search_conditions).
                      joins(:accounting_post).
                      includes(:accounting_post).
                      limit(20)
      end
    end
  end

  private

  # No search box even with search columns defined (only used for search action).
  def search_support?
    false
  end
end
