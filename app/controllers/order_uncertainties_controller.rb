# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class OrderUncertaintiesController < CrudController
  self.nesting = Order
  self.permitted_attrs = [:name, :probability, :impact, :measure]

  helper_method :index_path

  def index
    @chances = order.order_chances.list
    @risks = order.order_risks.list
  end

  private

  def index_path
    order_order_uncertainties_path(order, returning: true)
  end

  def order
    @order ||= Order.find(params[:order_id])
  end

  def model_scope
    case params.fetch(:type)
    when 'OrderRisk' then order.order_risks
    when 'OrderChance' then order.order_chances
    else not_found
    end
  end

  def model_class
    case params[:type]
    when 'OrderRisk' then OrderRisk
    when 'OrderChance' then OrderChance
    else OrderUncertainty
    end
  end

  def model_identifier
    params.fetch(:type).underscore
  end

  # A human readable plural name of the model.
  def models_label(plural = true)
    opts = { count: (plural ? 3 : 1) }
    opts[:default] = model_class.model_name.human.titleize
    opts[:default] = opts[:default].pluralize if plural

    model_class.model_name.human(opts)
  end

end
