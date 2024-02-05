# frozen_string_literal: true

class CreateAuthentications < ActiveRecord::Migration[5.2]
  def change
    create_table :authentications do |t|
      t.string :provider
      t.string :uid
      t.string :token
      t.string :token_secret
      t.references :employee

      t.timestamps
    end
  end
end
