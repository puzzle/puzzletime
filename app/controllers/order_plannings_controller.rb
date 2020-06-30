#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class OrderPlanningsController < Plannings::OrdersController
  skip_load_and_authorize_resource

  private

  def order
    @order ||= Order.find(params[:order_id])
  end
  alias subject order
end
