class ContractsController < CrudController
  self.nesting = Order

  self.permitted_attrs = :number, :start_date, :end_date, :payment_period, :reference, :sla

  def update
    super(location: edit_order_contract_path(order_id: parent))
  end

  private

  def order
    @order ||= Order.find(params[:order_id])
  end

  def entry
    order.try(:contract) || build_entry
  end

  def build_entry
    Contract.new(order: parent)
  end

  def parent_scope
    parent.send(:contract)
  end

end