# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class CreatePersonalAccessTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :personal_access_tokens do |t|
      t.references :employee, foreign_key: true
      t.string :name
      t.string :token_digest
      t.datetime :last_used_at
      t.text :scopes

      t.timestamps
    end
    add_index :personal_access_tokens, :token_digest, unique: true
  end
end
