class OrderCommentsController < CrudController
  self.nesting = Order
  self.permitted_attrs = :text

  def create
    super do |format, success|
      format.html { render :index } unless success
    end
  end

  private

  def assign_attributes
    entry.attributes = model_params
    entry.updater = current_user
    entry.creator ||= current_user
  end

  def parent_scope
    parent.send(:comments)
  end

end
