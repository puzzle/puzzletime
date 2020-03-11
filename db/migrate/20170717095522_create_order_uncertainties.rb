#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class CreateOrderUncertainties < ActiveRecord::Migration[5.0]
  def change
    create_table :order_uncertainties do |t|
      t.references :order, foreign_key: true, null: false
      t.string :type, null: false
      t.string :name, null: false
      t.integer :probability, null: false, default: 1
      t.integer :impact, null: false, default: 1
      t.text :measure

      t.timestamps
    end

    change_table :orders do |t|
      t.integer :major_risk_value
      t.integer :major_chance_value
    end
  end
end
