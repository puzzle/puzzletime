class OrderUncertaintiesController < CrudController
  self.nesting = Order
  self.permitted_attrs = [:name, :probability, :impact, :measure]

  helper_method :index_path

  def show
  end

  private

  def entry
    @entry ||= params[:id] ? find_entry : build_entry
  end

  def entries
    @entries ||= list_entries
  end

  def list_entries
    model_scope.list
  end

  def index_path
    order_order_uncertainties_path(order, returning: true)
  end

  def order
    @order ||= Order.find(params[:order_id])
  end

  def model_scope
    if params[:type] == 'OrderRisk'
      order.order_risks
    elsif params[:type] == 'OrderChance'
      order.order_chances
    else
      order.order_uncertainties
    end
  end

  def model_class
    if params[:type] == 'OrderRisk'
      OrderRisk
    elsif params[:type] == 'OrderChance'
      OrderChance
    else
      OrderUncertainty
    end
  end

  def model_identifier
    if params[:type] == 'OrderRisk'
      'order_risk'
    elsif params[:type] == 'OrderChance'
      'order_chance'
    else
      'order_uncertainty'
    end
  end
end
