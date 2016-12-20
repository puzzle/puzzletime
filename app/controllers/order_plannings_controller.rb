# encoding: utf-8

class OrderPlanningsController < Plannings::OrdersController

  skip_load_and_authorize_resource

  private

  def order
    @order ||= Order.find(params[:order_id])
  end
  alias subject order

end