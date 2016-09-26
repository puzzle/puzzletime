# encoding: utf-8

module PlanningsHelper

  def planning_legend_path(legend)
    case legend
    when Employee then plannings_employee_path(legend)
    when AccountingPost then plannings_order_path(legend.order)
    else raise ArgumentError, "invalid argument #{legend.inspect}"
    end
  end

end
