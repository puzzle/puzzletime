# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class AddOrderStatusDefault < ActiveRecord::Migration[5.1]
  def change
    add_column :order_statuses, :default, :boolean, { default: false, null: false }

    first_order_status = OrderStatus.list.first
    first_order_status.default = true
    first_order_status.save!
  end
end
