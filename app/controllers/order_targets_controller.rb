#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class OrderTargetsController < ApplicationController
  before_action :set_order
  before_action :authorize_class
  before_action :set_order_targets

  def show
  end

  def update
    update_targets
    flash.now[:notice] = I18n.t('crud.update.flash.success', model: 'Ziele') if @errors.blank?
    render 'show'
  end

  private

  def update_targets
    @errors = OrderTarget.new.errors
    @order_targets.each do |target|
      unless target.update(target_params(target))
        target.errors.each { |attr, msg| @errors.add(attr, msg) }
      end
    end
  end

  def target_params(target)
    p = (params[:order] || {})["target_#{target.id}"]
    p ? p.permit(:rating, :comment) : {}
  end

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_order_targets
    @order_targets = @order.targets.list.to_a
  end

  def authorize_class
    authorize!(:"#{action_name}_targets", @order)
  end
end
