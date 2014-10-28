class OrderTargetsController < CrudController

  self.nesting = Order

  before_action :set_choosable_orders

  private

  def parent_scope
    parent.targets
  end

  def set_choosable_orders
    @choosable_orders = Order.list
  end

end