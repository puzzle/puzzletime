# frozen_string_literal: true

class CreateFlatrates < ActiveRecord::Migration[7.1]
  def change
    create_table :flatrates do |t|
      t.string :name
      t.boolean :active, default: true, null: false
      t.text :description
      t.decimal :amount
      t.integer :periodicity, array: true, default: []
      t.references :accounting_post, foreign_key: true

      t.timestamps
    end

    create_join_table :flatrates, :invoices
  end
end
