# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class OrderPlanningsController < Plannings::OrdersController
  skip_load_and_authorize_resource

  # AJAX
  def preview_total_selected
    cell_ids = params[:cell_ids] || []
    Rails.logger.info("cell_ids: #{cell_ids.inspect}")
    Rails.logger.info("params: #{params.inspect}")
    @cells = Planning.where(id: cell_ids)
    @total_selected_hours = @cells.sum(&:percent) * 8 / 100.0

    respond_to do |format|
      format.js
    end
  end

  private

  def order
    @order ||= Order.find(params[:order_id])
  end
  alias subject order
end
