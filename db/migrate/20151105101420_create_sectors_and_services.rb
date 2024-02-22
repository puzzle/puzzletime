# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class CreateSectorsAndServices < ActiveRecord::Migration[5.1]
  def change
    create_table :sectors do |t|
      t.string :name, null: false, unique: true
      t.boolean :active, null: false, default: true
    end

    create_table :services do |t|
      t.string :name, null: false, unique: true
      t.boolean :active, null: false, default: true
    end

    add_column :clients, :sector_id, :integer
    add_column :accounting_posts, :service_id, :integer

    add_index :clients, :sector_id
    add_index :accounting_posts, :service_id

    null = Service.create!(name: 'Null', active: false)
    AccountingPost.update_all(service_id: null.id)
  end
end
