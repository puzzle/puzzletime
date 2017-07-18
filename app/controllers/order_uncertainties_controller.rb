class OrderUncertaintiesController < CrudController
  self.nesting = Order

  def show
  end

  private

  def entry
    @entry ||= params[:id] ? find_entry : build_entry
  end

  def list_entries
    model_scope.list
  end

  def model_scope
    order.order_uncertainties
  end

  def order
    @order ||= Order.find(params[:order_id])
  end
end
