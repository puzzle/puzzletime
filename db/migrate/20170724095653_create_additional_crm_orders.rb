#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class CreateAdditionalCrmOrders < ActiveRecord::Migration[5.1]
  def change
    create_table :additional_crm_orders do |t|
      t.belongs_to :order, null: false, index: true
      t.string :crm_key, null: false
      t.string :name
    end
  end
end
