class ContractsController < CrudController
  self.nesting = Order

  self.permitted_attrs = :text

  def update
    super(location: order_contract_path(entry, order_id: parent))
  end

  private

  def order
    @order ||= Order.find(params[:order_id])
  end

  def build_entry
    Contract.new(order: parent)
  end

  def parent_scope
    parent.send(:contract)
  end

end