# frozen_string_literal: true

#  Copyright (c) 2006-2024, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class CreateMarketOpportunities < ActiveRecord::Migration[7.1]
  def change
    create_table :market_opportunities do |t|
      t.string :name, null: false, index: { unique: true }
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_column :accounting_posts, :market_opportunity_id, :integer
    add_index :accounting_posts, :market_opportunity_id
  end
end
