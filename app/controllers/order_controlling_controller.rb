#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class OrderControllingController < ApplicationController

  def show
    authorize!(:controlling, order)
    @controlling = Order::Controlling.new(order)
  end

  private

  def order
    @order ||= Order.find(params[:order_id])
  end

end
